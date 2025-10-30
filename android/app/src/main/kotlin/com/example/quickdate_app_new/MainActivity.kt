import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.res.Resources

class MainActivity: FlutterActivity() {
    private val CHANNEL = "quickdate/razorpay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRazorpayKey") {
                val keyId = resources.getString(R.string.razorpay_api_Key)
                result.success(keyId)
            } else {
                result.notImplemented()
            }
        }
    }
}
