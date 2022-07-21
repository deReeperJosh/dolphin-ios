// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingGroupEditViewController.h"

#import "InputCommon/ControllerEmu/ControlGroup/ControlGroup.h"
#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/ControllerEmu/Setting/NumericSetting.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MappingGroupEditBoolCell.h"
#import "MappingGroupEditControlCell.h"
#import "MappingGroupEditDoubleCell.h"
#import "MappingGroupEditEnabledCell.h"

typedef NS_ENUM(NSInteger, DOLMappingGroupEditSection) {
  DOLMappingGroupEditSectionEnableSwitch,
  DOLMappingGroupEditSectionControls,
  DOLMappingGroupEditSectionNumericSettings,
  DOLMappingGroupEditSectionCount
};

@interface MappingGroupEditViewController ()

@end

@implementation MappingGroupEditViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.title = DOLCoreLocalizedString(CppToFoundationString(self.controlGroup->ui_name));
}

- (void)enableSwitchValueDidChange:(MappingGroupEditEnabledCell*)cell {
  self.controlGroup->enabled = cell.enabledSwitch.on;
  
  for (int i = 0; i < self.controlGroup->controls.size(); i++) {
    MappingGroupEditControlCell* controlCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:DOLMappingGroupEditSectionControls]];
    
    [self updateControlCellBasedOnEnabled:controlCell];
  }
  
  for (int i = 0; i < self.controlGroup->numeric_settings.size(); i++) {
    switch (self.controlGroup->numeric_settings[i]->GetType()) {
      case ControllerEmu::SettingType::Double: {
        MappingGroupEditDoubleCell* doubleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:DOLMappingGroupEditSectionNumericSettings]];
        
        [self updateDoubleCellBasedOnEnabled:doubleCell];
        
        break;
      }
      case ControllerEmu::SettingType::Bool: {
        MappingGroupEditBoolCell* boolCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:DOLMappingGroupEditSectionNumericSettings]];
        
        [self updateBoolCellBasedOnEnabled:boolCell];
        
        break;
      }
      default:
        break;
    }
  }
}

- (void)updateControlCellBasedOnEnabled:(MappingGroupEditControlCell*)cell {
  bool enabled = self.controlGroup->enabled;
  
  cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
  cell.nameLabel.textColor = enabled ? [UIColor labelColor] : [UIColor systemGrayColor];
}

- (void)updateDoubleCellBasedOnEnabled:(MappingGroupEditDoubleCell*)cell {
  bool enabled = self.controlGroup->enabled;
  
  cell.nameLabel.textColor = enabled ? [UIColor labelColor] : [UIColor systemGrayColor];
  cell.textField.enabled = enabled;
}

- (void)updateBoolCellBasedOnEnabled:(MappingGroupEditBoolCell*)cell {
  bool enabled = self.controlGroup->enabled;
  
  cell.nameLabel.textColor = enabled ? [UIColor labelColor] : [UIColor systemGrayColor];
  cell.enabledSwitch.enabled = enabled;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return DOLMappingGroupEditSectionCount;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case DOLMappingGroupEditSectionEnableSwitch:
      return self.controlGroup->default_value != ControllerEmu::ControlGroup::DefaultValue::AlwaysEnabled ? 1 : 0;
    case DOLMappingGroupEditSectionControls:
      return self.controlGroup->controls.size();
    case DOLMappingGroupEditSectionNumericSettings:
      return self.controlGroup->numeric_settings.size();
    default:
      return 0;
  }
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
  // If there are no rows, don't reserve space for a section header.
  if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
    return CGFLOAT_MIN;
  }
  
  return UITableViewAutomaticDimension;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  switch (indexPath.section) {
    case DOLMappingGroupEditSectionEnableSwitch: {
      MappingGroupEditEnabledCell* enabledCell = [tableView dequeueReusableCellWithIdentifier:@"EnabledCell" forIndexPath:indexPath];
      
      enabledCell.delegate = self;
      
      return enabledCell;
    }
    case DOLMappingGroupEditSectionControls: {
      const auto lock = ControllerEmu::EmulatedController::GetStateLock();
      
      const auto& control = self.controlGroup->controls[indexPath.row];
      
      MappingGroupEditControlCell* controlCell = [tableView dequeueReusableCellWithIdentifier:@"ControlCell" forIndexPath:indexPath];
      
      NSString* name = CppToFoundationString(control->ui_name);
      if (control->translate == ControllerEmu::Translate) {
        name = DOLCoreLocalizedString(name);
      }
      
      std::string expression = control->control_ref->GetExpression();
      if (expression.empty()) {
        expression = "—";
      }
      
      controlCell.nameLabel.text = name;
      controlCell.expressionLabel.text = CppToFoundationString(expression);
      
      [self updateControlCellBasedOnEnabled:controlCell];
      
      return controlCell;
    }
    case DOLMappingGroupEditSectionNumericSettings: {
      const auto& setting = self.controlGroup->numeric_settings[indexPath.row];
      
      switch (setting->GetType()) {
        case ControllerEmu::SettingType::Double: {
          const auto& doubleSetting = static_cast<ControllerEmu::NumericSetting<double>*>(setting.get());
          
          MappingGroupEditDoubleCell* doubleCell = [tableView dequeueReusableCellWithIdentifier:@"DoubleCell" forIndexPath:indexPath];
          
          doubleCell.nameLabel.text = DOLCoreLocalizedString(CToFoundationString(doubleSetting->GetUIName()));
          doubleCell.textField.text = [NSString localizedStringWithFormat:@"%f", doubleSetting->GetValue()];
          
          [self updateDoubleCellBasedOnEnabled:doubleCell];
          
          return doubleCell;
        }
        case ControllerEmu::SettingType::Bool: {
          const auto& boolSetting = static_cast<ControllerEmu::NumericSetting<bool>*>(setting.get());
          
          MappingGroupEditBoolCell* boolCell = [tableView dequeueReusableCellWithIdentifier:@"BoolCell" forIndexPath:indexPath];
          
          boolCell.nameLabel.text = DOLCoreLocalizedString(CToFoundationString(boolSetting->GetUIName()));
          boolCell.enabledSwitch.on = boolSetting->GetValue();
          
          [self updateBoolCellBasedOnEnabled:boolCell];
          
          return boolCell;
        }
        default:
          break;
      }
    }
    default:
      return nil;
  }
  
  return nil;
}

@end
