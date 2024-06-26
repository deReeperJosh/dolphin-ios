// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsChoiceCell.h"

#import "Common/Config/Config.h"

@implementation GraphicsChoiceCell  {
  const Config::Info<int>* _setting;
}

- (void)registerSetting:(const Config::Info<int>&) setting {
  if (_setting != nullptr) {
    [NSException raise:@"DOLCellAlreadyRegisteredException" format:@"GraphicsChoiceCell already registered"];
    return;
  }
  
  _setting = &setting;
  
  UIFont* font;
  if (Config::GetActiveLayerForConfig(setting) != Config::LayerType::Base) {
    font = [UIFont boldSystemFontOfSize:self.choiceNameLabel.font.pointSize];
  } else {
    font = [UIFont systemFontOfSize:self.choiceNameLabel.font.pointSize];
  }
  
  self.choiceNameLabel.font = font;
}

@end
