// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MsgAlertManager.h"

#import <mutex>
#import <UIKit/UIKit.h>

#import "Common/Event.h"
#import "Common/MsgHandler.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MainSceneCoordinator.h"

@interface MsgAlertManager ()

// We need to declare this early so the static function below can see it.
- (bool)handleAlertWithCaption:(const char*)caption text:(const char*)text question:(bool)question style:(Common::MsgType)style;

@end

static bool MsgAlert(const char* caption, const char* text, bool question, Common::MsgType style) {
  return [[MsgAlertManager shared] handleAlertWithCaption:caption text:text question:question style:style];
}

@implementation MsgAlertManager {
  std::mutex _alertLock;
  Common::Event _waitEvent;
}

+ (MsgAlertManager*)shared {
  static MsgAlertManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (void)registerHandler {
  Common::RegisterMsgAlertHandler(MsgAlert);
}

- (bool)handleAlertWithCaption:(const char*)caption text:(const char*)text question:(bool)question style:(Common::MsgType)style {
  std::lock_guard<std::mutex> guard(_alertLock);
  
  NSString* foundationCaption = CToFoundationString(caption);
  NSString* foundationText = CToFoundationString(text);
  
  // Log to console as a backup
  NSLog(@"MsgAlert - %@: %@ (question: %d)", foundationCaption, foundationText, question ? 1 : 0);
  
  UIWindowScene* mainScene = [MainSceneCoordinator shared].mainScene;

  if (mainScene == nil) {
    // Dunno what we can do here - the main scene is somehow disconnected?
    return false;
  }
  
  __block bool confirmed = false;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    UIWindow* window = [[UIWindow alloc] initWithWindowScene:mainScene];
    window.frame = [UIScreen mainScreen].bounds;
    window.rootViewController = [[UIViewController alloc] init];
    window.windowLevel = UIWindowLevelAlert;
    
    UIWindow* topWindow = mainScene.windows.lastObject;
    window.windowLevel = topWindow.windowLevel + 1;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:foundationCaption message:foundationText preferredStyle:UIAlertControllerStyleAlert];
    
    void (^finish)() = ^void() {
      [window setHidden:true];
      self->_waitEvent.Set();
    };

    if (question) {
      [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"No") style:UIAlertActionStyleDefault
        handler:^(UIAlertAction* action) {
        confirmed = false;

        finish();
      }]];

      [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Yes") style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
        confirmed = true;

        finish();
      }]];
    }
    else
    {
      [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault
        handler:^(UIAlertAction* action) {
        confirmed = true;
        
        finish();
      }]];
    }

    [window makeKeyAndVisible];

    [window.rootViewController presentViewController:alert animated:true completion:nil];
  });

  // Wait for a button press
  _waitEvent.Wait();

  return confirmed;
}

@end
