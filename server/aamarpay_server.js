require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors());
// Use urlencoded to match x-www-form-urlencoded expected by client
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

const PORT = process.env.PORT || 3000;

// Config and simple in-memory DB
const config = {
  aamarpay_store_id: process.env.AAMARPAY_STORE_ID || 'demo',
  aamarpay_signature_key: process.env.AAMARPAY_SIGNATURE_KEY || 'demo_sig',
  aamarpay_mode: process.env.AAMARPAY_MODE || 'sandbox',
  weekly_pro_plan: parseInt(process.env.WEEKLY_PRO_PLAN || '800', 10),
  monthly_pro_plan: parseInt(process.env.MONTHLY_PRO_PLAN || '2500', 10),
  yearly_pro_plan: parseInt(process.env.YEARLY_PRO_PLAN || '28000', 10),
  lifetime_pro_plan: parseInt(process.env.LIFETIME_PRO_PLAN || '50000', 10),
  bag_of_credits_price: parseInt(process.env.BAG_OF_CREDITS_PRICE || '100', 10),
  bag_of_credits_amount: parseInt(process.env.BAG_OF_CREDITS_AMOUNT || '10', 10),
  box_of_credits_price: parseInt(process.env.BOX_OF_CREDITS_PRICE || '500', 10),
  box_of_credits_amount: parseInt(process.env.BOX_OF_CREDITS_AMOUNT || '60', 10),
  chest_of_credits_price: parseInt(process.env.CHEST_OF_CREDITS_PRICE || '1000', 10),
  chest_of_credits_amount: parseInt(process.env.CHEST_OF_CREDITS_AMOUNT || '150', 10),
};

// Very small in-memory storage to emulate users and payments
const db = {
  users: new Map(), // userId -> { id, name, email, phone, balance, is_pro, pro_type, pro_time, aamarpay_tran_id }
  payments: [], // payment records
};

// Helper to create or fetch a user by email for demo purposes
function findOrCreateUser({ name, email, phone }) {
  for (const user of db.users.values()) {
    if (user.email === email) return user;
  }
  const id = uuidv4();
  const user = {
    id,
    name,
    email,
    phone,
    balance: 0,
    is_pro: false,
    pro_type: 0,
    pro_time: null,
    aamarpay_tran_id: '',
  };
  db.users.set(id, user);
  return user;
}

// POST /aamarpay/get
app.post('/aamarpay/get', (req, res) => {
  const types = ['credit', 'go_pro'];
  const { type, price, name, email, phone } = req.body || {};
  if (!type || !types.includes(type) || !price || isNaN(Number(price)) || Number(price) <= 0 || !name || !email || !phone) {
    return res.status(400).json({ status: 400, message: 'missing_fields' });
  }

  const realprice = parseInt(price, 10);
  let amount = 0;
  let membershipType = 0;

  if (type === 'go_pro') {
    if (realprice === config.weekly_pro_plan) membershipType = 1;
    else if (realprice === config.monthly_pro_plan) membershipType = 2;
    else if (realprice === config.yearly_pro_plan) membershipType = 3;
    else if (realprice === config.lifetime_pro_plan) membershipType = 4;
    else return res.status(400).json({ status: 400, message: 'Please enter the correct amount for pro plan' });
  } else if (type === 'credit') {
    if (realprice === config.bag_of_credits_price) amount = config.bag_of_credits_amount;
    else if (realprice === config.box_of_credits_price) amount = config.box_of_credits_amount;
    else if (realprice === config.chest_of_credits_price) amount = config.chest_of_credits_amount;
    else return res.status(400).json({ status: 400, message: 'Please enter the correct amount for credit pack' });
  }

  // create unique transaction id
  const tran_id = Math.floor(1000000 + Math.random() * 8999999).toString();

  // persist on user record
  const user = findOrCreateUser({ name, email, phone });
  user.aamarpay_tran_id = tran_id;
  db.users.set(user.id, user);

  // Build a simulated Aamarpay hosted url. In real server, you'd POST to Aamarpay request.php with store_id and signature_key.
  const base = config.aamarpay_mode === 'sandbox' ? 'https://sandbox.aamarpay.com/' : 'https://secure.aamarpay.com/';
  // For demo, create a fake forward path that includes the tran_id so client can detect it
  const forwardPath = `request.php?tran_id=${tran_id}&type=${type}&amount=${realprice}`;
  const hostedUrl = base + forwardPath;

  return res.json({ status: 200, url: hostedUrl });
});

// POST /aamarpay/success
app.post('/aamarpay/success', (req, res) => {
  const types = ['credit', 'go_pro'];
  const { type, amount, mer_txnid, pay_status } = req.body || {};
  if (!type || !types.includes(type) || !amount || !mer_txnid || !pay_status || pay_status !== 'Successful') {
    return res.status(400).json({ status: 400, message: 'missing_fields_or_invalid_status' });
  }

  // find user by aamarpay_tran_id
  const user = Array.from(db.users.values()).find(u => u.aamarpay_tran_id === mer_txnid);
  if (!user) return res.status(400).json({ status: 400, message: 'No pending payment found' });

  const price = parseInt(amount, 10);

  // Avoid double-processing: if tran_id was already cleared, treat as idempotent success
  if (!user.aamarpay_tran_id || user.aamarpay_tran_id !== mer_txnid) {
    // If already processed, return success idempotently
    return res.json({ message: 'SUCCESS', code: 200 });
  }

  if (type === 'credit') {
    // verify amount matches one of the known packs
    let creditAmount = 0;
    if (price === config.bag_of_credits_price) creditAmount = config.bag_of_credits_amount;
    else if (price === config.box_of_credits_price) creditAmount = config.box_of_credits_amount;
    else if (price === config.chest_of_credits_price) creditAmount = config.chest_of_credits_amount;
    else return res.status(400).json({ status: 400, message: 'Please enter the correct amount' });

    user.balance = (user.balance || 0) + creditAmount;
    db.payments.push({ user_id: user.id, amount: price, type: 'CREDITS', pro_plan: 0, credit_amount: creditAmount, via: 'Aamarpay', created_at: Date.now() });
  } else if (type === 'go_pro') {
    let membershipType = 0;

    if (price === config.weekly_pro_plan) membershipType = 1;
    else if (price === config.monthly_pro_plan) membershipType = 2;
    else if (price === config.yearly_pro_plan) membershipType = 3;
    else if (price === config.lifetime_pro_plan) membershipType = 4;
    else return res.status(400).json({ status: 400, message: 'Please enter the correct amount' });

    user.is_pro = true;
    user.pro_type = membershipType;
    user.pro_time = Date.now();

    db.payments.push({ user_id: user.id, amount: price, type: 'PRO', pro_plan: membershipType, credit_amount: 0, via: 'Aamarpay', created_at: Date.now() });
  }

  // clear tran id
  user.aamarpay_tran_id = '';
  db.users.set(user.id, user);

  // call affiliate revenue registration (no-op in demo but logged)
  console.log(`RegisterAffRevenue called for user ${user.id} amount ${price}`);

  return res.json({ message: 'SUCCESS', code: 200 });
});

// NEW: GET /authorize/config - provide client key and apiLoginID to client for Accept.js
app.get('/authorize/config', (req, res) => {
  const { authorize_login_id, authorize_transaction_key } = config;
  // Client key must be provided via environment for tokenization; we expect AUTHORIZE_CLIENT_KEY in env
  const clientKey = process.env.AUTHORIZE_CLIENT_KEY || '';
  if (!authorize_login_id || !clientKey) {
    return res.status(400).json({ status: 400, message: 'Authorize.Net not configured on server' });
  }
  return res.json({ status: 200, apiLoginId: authorize_login_id, clientKey, mode: config.authorize_mode });
});

// UPDATED: POST /authorize/pay - now expects tokenized opaque data (dataDescriptor + dataValue)
app.post('/authorize/pay', async (req, res) => {
  try {
    const types = ['credit', 'go_pro', 'unlock_private_photo', 'lock_pro_video'];
    const { type, price, name, email, phone, dataDescriptor, dataValue } = req.body || {};

    // Require tokenized payment data (opaqueData)
    if (!type || !types.includes(type) || !price || isNaN(Number(price)) || Number(price) <= 0 || !dataDescriptor || !dataValue) {
      return res.status(400).json({ status: 400, message: 'please check your details or provide tokenized payment data' });
    }

    const realprice = parseInt(price, 10);
    let amount = 0;
    let membershipType = 0;

    if (type === 'go_pro') {
      if (realprice === config.weekly_pro_plan) membershipType = 1;
      else if (realprice === config.monthly_pro_plan) membershipType = 2;
      else if (realprice === config.yearly_pro_plan) membershipType = 3;
      else if (realprice === config.lifetime_pro_plan) membershipType = 4;
      else return res.status(400).json({ status: 400, message: 'Please enter the correct amount for pro plan' });
    } else if (type === 'credit') {
      if (realprice === config.bag_of_credits_price) amount = config.bag_of_credits_amount;
      else if (realprice === config.box_of_credits_price) amount = config.box_of_credits_amount;
      else if (realprice === config.chest_of_credits_price) amount = config.chest_of_credits_amount;
      else return res.status(400).json({ status: 400, message: 'Please enter the correct amount for credit pack' });
    }

    // If Authorize.Net credentials aren't set, simulate a successful response for demo
    if (!config.authorize_login_id || !config.authorize_transaction_key) {
      console.log('Authorize.Net credentials not configured. Returning simulated success (demo mode).');

      // apply business logic: find or create user if provided
      const user = findOrCreateUser({ name: name || 'Demo User', email: email || 'demo@example.com', phone: phone || '0000000000' });

      if (type === 'credit') {
        user.balance = (user.balance || 0) + amount;
        db.payments.push({ user_id: user.id, amount: realprice, type: 'CREDITS', pro_plan: 0, credit_amount: amount, via: 'Authorize' });
        return res.json({ status: 200, message: 'payment Success', credit_amount: user.balance, url: 'https://example.com/ProSuccess' });
      } else if (type === 'go_pro') {
        user.is_pro = true;
        user.pro_type = membershipType;
        user.pro_time = Date.now();
        db.payments.push({ user_id: user.id, amount: realprice, type: 'PRO', pro_plan: membershipType, credit_amount: 0, via: 'Authorize' });
        return res.json({ status: 200, message: 'payment Success', url: 'https://example.com/ProSuccess?paymode=pro' });
      } else {
        // other types: mark success generically
        db.payments.push({ user_id: user.id, amount: realprice, type: type, pro_plan: 0, credit_amount: 0, via: 'Authorize' });
        return res.json({ status: 200, message: 'payment Success', url: 'https://example.com/ProSuccess' });
      }
    }

    // Build merchant authentication
    const merchantAuthenticationType = new ApiContracts.MerchantAuthenticationType();
    merchantAuthenticationType.setName(config.authorize_login_id);
    merchantAuthenticationType.setTransactionKey(config.authorize_transaction_key);

    // Build opaque data object from client tokenization
    const opaqueData = new ApiContracts.OpaqueDataType();
    opaqueData.setDataDescriptor(dataDescriptor);
    opaqueData.setDataValue(dataValue);

    const paymentType = new ApiContracts.PaymentType();
    paymentType.setOpaqueData(opaqueData);

    const transactionRequestType = new ApiContracts.TransactionRequestType();
    transactionRequestType.setTransactionType(ApiContracts.TransactionTypeEnum.AUTHCAPTURETRANSACTION);
    transactionRequestType.setAmount(realprice);
    transactionRequestType.setPayment(paymentType);

    const createRequest = new ApiContracts.CreateTransactionRequest();
    createRequest.setMerchantAuthentication(merchantAuthenticationType);
    createRequest.setTransactionRequest(transactionRequestType);

    const ctrl = new ApiControllers.CreateTransactionController(createRequest.getJSON());
    const env = config.authorize_mode === 'SANDBOX' ? ApiControllers.Environment.SANDBOX : ApiControllers.Environment.PRODUCTION;

    ctrl.execute(function(){
      const apiResponse = ctrl.getResponse();
      if (apiResponse == null) {
        return res.status(500).json({ status: 500, message: 'unknown_error' });
      }

      const responseCode = apiResponse.getMessages().getResultCode();
      if (responseCode && responseCode === ApiContracts.MessageTypeEnum.OK) {
        const tResponse = apiResponse.getTransactionResponse();
        if (tResponse != null && tResponse.getMessages() != null) {
          // Success - apply business logic
          const user = findOrCreateUser({ name: name || 'Demo User', email: email || 'demo@example.com', phone: phone || '0000000000' });

          if (type === 'credit') {
            user.balance = (user.balance || 0) + amount;
            db.payments.push({ user_id: user.id, amount: realprice, type: 'CREDITS', pro_plan: 0, credit_amount: amount, via: 'Authorize' });
            return res.json({ status: 200, message: 'payment Success', credit_amount: user.balance, url: 'https://example.com/ProSuccess' });
          } else if (type === 'go_pro') {
            user.is_pro = true;
            user.pro_type = membershipType;
            user.pro_time = Date.now();
            db.payments.push({ user_id: user.id, amount: realprice, type: 'PRO', pro_plan: membershipType, credit_amount: 0, via: 'Authorize' });
            return res.json({ status: 200, message: 'payment Success', url: 'https://example.com/ProSuccess?paymode=pro' });
          } else {
            db.payments.push({ user_id: user.id, amount: realprice, type: type, pro_plan: 0, credit_amount: 0, via: 'Authorize' });
            return res.json({ status: 200, message: 'payment Success', url: 'https://example.com/ProSuccess' });
          }

        } else {
          // Transaction failed - extract errors
          const tResponse = apiResponse.getTransactionResponse();
          let err = 'unknown_error';
          if (tResponse && tResponse.getErrors()) {
            err = tResponse.getErrors()[0].getErrorText();
          }
          return res.status(400).json({ status: 400, message: err });
        }
      } else {
        // API-level failure
        const tResponse = apiResponse.getTransactionResponse();
        let err = 'unknown_error';
        if (tResponse && tResponse.getErrors()) {
          err = tResponse.getErrors()[0].getErrorText();
        } else if (apiResponse.getMessages() && apiResponse.getMessages().getMessage()) {
          err = apiResponse.getMessages().getMessage()[0].getText();
        }
        return res.status(400).json({ status: 400, message: err });
      }
    }, env);

  } catch (ex) {
    console.error('Authorize /pay error', ex);
    return res.status(500).json({ status: 500, message: 'internal_error' });
  }
});

// Small endpoint to view in-memory db for debugging (do not enable in production)
app.get('/debug/db', (req, res) => {
  const users = Array.from(db.users.values());
  return res.json({ users, payments: db.payments });
});

app.listen(PORT, () => {
  console.log(`Aamarpay demo server listening on http://localhost:${PORT}`);
});
