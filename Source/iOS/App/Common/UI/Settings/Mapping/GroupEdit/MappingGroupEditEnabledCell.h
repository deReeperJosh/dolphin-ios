// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

@protocol MappingGroupEditEnableCellDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface MappingGroupEditEnabledCell : UITableViewCell

@property (weak, nonatomic, nullable) id<MappingGroupEditEnableCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* enabledSwitch;

@end

NS_ASSUME_NONNULL_END
