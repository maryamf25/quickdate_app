# File Cleanup Instructions

## Files to Delete (Extra/Unnecessary Files):

1. `Z:\GitAmnaProject\lib\screens\random_user_profile_screen_clean.dart`
2. `Z:\GitAmnaProject\lib\screens\chats_screen_new.dart`
3. `Z:\GitAmnaProject\lib\screens\chats_screen_fixed.dart` (if exists)
4. `Z:\GitAmnaProject\NAVIGATION_FIX_SUMMARY.md` (optional documentation file)

## Files to Keep (Main Files):

✅ `Z:\GitAmnaProject\lib\screens\random_user_profile_screen.dart` - KEEP
✅ `Z:\GitAmnaProject\lib\screens\chats_screen.dart` - KEEP  
✅ `Z:\GitAmnaProject\lib\screens\home_screen.dart` - KEEP
✅ `Z:\GitAmnaProject\lib\screens\chat_conversation_screen.dart` - KEEP

## How to Delete Extra Files:

### Option 1: Using File Explorer
1. Open File Explorer
2. Navigate to `Z:\GitAmnaProject\lib\screens\`
3. Delete the following files:
   - `random_user_profile_screen_clean.dart`
   - `chats_screen_new.dart`
   - `chats_screen_fixed.dart` (if present)

### Option 2: Using Command Prompt
```cmd
cd Z:\GitAmnaProject\lib\screens
del random_user_profile_screen_clean.dart
del chats_screen_new.dart
del chats_screen_fixed.dart
```

## Status After Cleanup:
- ✅ Navigation will work correctly (Settings & Chats buttons fixed)
- ✅ Chat functionality will work with backend integration
- ✅ User profile screens will work correctly
- ✅ Clean codebase with no duplicate files

## Verification:
After deleting the extra files, the navigation should work perfectly:
- Clicking "Chats" (index 3) → Shows ChatsScreen
- Clicking "Settings" (index 4) → Shows Settings
- No more RangeError crashes
- All imports properly resolved
