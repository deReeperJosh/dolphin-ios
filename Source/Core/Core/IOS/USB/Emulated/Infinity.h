// Copyright 2023 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <array>
#include <map>
#include <mutex>
#include <queue>
#include <vector>

#include "Common/CommonTypes.h"
#include "Common/IOFile.h"
#include "Core/IOS/USB/Common.h"

namespace IOS::HLE::USB
{
struct InfinityFigureInfo final
{
  std::string type;
  u64 uid;
  u16 character;
  u32 extra;
};

extern const std::map<const char*, const InfinityFigureInfo> list_infinity_figures;
class InfinityUSB final : public Device
{
public:
  InfinityUSB(Kernel& ios, const std::string& device_name);
  ~InfinityUSB();
  DeviceDescriptor GetDeviceDescriptor() const override;
  std::vector<ConfigDescriptor> GetConfigurations() const override;
  std::vector<InterfaceDescriptor> GetInterfaces(u8 config) const override;
  std::vector<EndpointDescriptor> GetEndpoints(u8 config, u8 interface, u8 alt) const override;
  bool Attach() override;
  bool AttachAndChangeInterface(u8 interface) override;
  int CancelTransfer(u8 endpoint) override;
  int ChangeInterface(u8 interface) override;
  int GetNumberOfAltSettings(u8 interface) override;
  int SetAltSetting(u8 alt_setting) override;
  int SubmitTransfer(std::unique_ptr<CtrlMessage> message) override;
  int SubmitTransfer(std::unique_ptr<BulkMessage> message) override;
  int SubmitTransfer(std::unique_ptr<IntrMessage> message) override;
  int SubmitTransfer(std::unique_ptr<IsoMessage> message) override;
  void ScheduleTransfer(std::unique_ptr<TransferCommand> command, const std::array<u8, 32>& data,
                        s32 expected_count, u64 expected_time_us);

private:
  Kernel& m_ios;
  u16 m_vid = 0;
  u16 m_pid = 0;
  u8 m_active_interface = 0;
  bool m_device_attached = false;
  DeviceDescriptor m_device_descriptor;
  std::vector<ConfigDescriptor> m_config_descriptor;
  std::vector<InterfaceDescriptor> m_interface_descriptor;
  std::vector<EndpointDescriptor> m_endpoint_descriptor;
  std::queue<std::array<u8, 32>> m_queries;
  std::queue<std::unique_ptr<IntrMessage>> m_response_list;
};

struct InfinityFigure final
{
  File::IOFile inf_file;
  std::array<u8, 0x14 * 0x10> data{};
  bool present = false;
  u8 order_added = 255;
  void Save();
};

class InfinityBase final
{
public:
  bool HasFigureBeenAddedRemoved();
  std::array<u8, 32> GetAddedRemovedResponse();
  void GetBlankResponse(u8 sequence, u8* reply_buf);
  void GetPresentFigures(u8 sequence, u8* reply_buf);
  void GetFigureIdentifier(u8 fig_num, u8 sequence, u8* reply_buf);
  void QueryBlock(u8 fig_num, u8 block, u8* reply_buf, u8 sequence);
  void WriteBlock(u8 fig_num, u8 block, const u8* to_write_buf, u8* reply_buf, u8 sequence);
  void RemoveFigure(u8 position);
  std::string LoadFigure(u8* buf, File::IOFile in_file, u8 position);
  bool CreateFigure(const std::string& file_path, u16 character);
  void CopyBlockToFile(std::array<u8, 16> data, u8* file, u8 position);
  std::string FindFigure(u16 character);
  void GenerateSeed(u32 seed);
  u32 GetNext();
  u64 Scramble(u32 num_to_scramble, u32 garbage);
  u32 Descramble(u64 num_to_descramble);
  u8 GenerateChecksum(u8* data, int num_of_bytes);

protected:
  std::mutex infinity_mutex;
  InfinityFigure m_player_one;
  InfinityFigure m_player_two;
  InfinityFigure m_player_one_ability;
  InfinityFigure m_player_two_ability;
  InfinityFigure m_hexagon;

private:
  u32 _a;
  u32 _b;
  u32 _c;
  u32 _d;
  u32 RotateLeft(u32 x, u8 d);
  u8 m_figure_order = 0;
  std::queue<std::array<u8, 32>> m_figure_added_removed_response;

  const std::vector<u8> SHA1_CONSTANT = {0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C,
                                         0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE,
                                         0x28, 0x63, 0x29, 0x20, 0x44, 0x69, 0x73, 0x6e,
                                         0x65, 0x79, 0x20, 0x32, 0x30, 0x31, 0x33};

  const std::array<u8, 16> BLANK_BLOCK = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
};
}  // namespace IOS::HLE::USB
