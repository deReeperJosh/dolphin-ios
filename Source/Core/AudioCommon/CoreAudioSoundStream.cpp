// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include <AudioUnit/AudioUnit.h>

#include "AudioCommon/CoreAudioSoundStream.h"
#include "Common/Logging/Log.h"

OSStatus CoreAudioSound::callback(void* ref_con, AudioUnitRenderActionFlags* action_flags,
                                  const AudioTimeStamp* timestamp, UInt32 bus_number,
                                  UInt32 number_frames, AudioBufferList* io_data)
{
  auto* const sound = static_cast<CoreAudioSound*>(ref_con);
  for (UInt32 i = 0; i < io_data->mNumberBuffers; i++)
  {
    const AudioBuffer buffer = io_data->mBuffers[i];
    sound->m_mixer->Mix(static_cast<short*>(buffer.mData), buffer.mDataByteSize / 4);
  }

  return noErr;
}

bool CoreAudioSound::Init()
{
  OSStatus err;
  AURenderCallbackStruct callback_struct;
  AudioStreamBasicDescription format;
  AudioComponentDescription desc;
  AudioComponent component;

  desc.componentType = kAudioUnitType_Output;
  desc.componentSubType = kAudioUnitSubType_RemoteIO;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;
  desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  component = AudioComponentFindNext(nullptr, &desc);
  if (component == nullptr)
  {
    ERROR_LOG_FMT(AUDIO, "error finding audio component");
    return false;
  }

  err = AudioComponentInstanceNew(component, &audio_unit);
  if (err != noErr)
  {
    ERROR_LOG_FMT(AUDIO, "error opening audio component");
    return false;
  }

  FillOutASBDForLPCM(format, m_mixer->GetSampleRate(), 2, 16, 16, false, false, false);
  err = AudioUnitSetProperty(audio_unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0,
                             &format, sizeof(AudioStreamBasicDescription));
  if (err != noErr)
  {
    ERROR_LOG_FMT(AUDIO, "error setting audio format");
    return false;
  }

  callback_struct.inputProc = callback;
  callback_struct.inputProcRefCon = this;
  err = AudioUnitSetProperty(audio_unit, kAudioUnitProperty_SetRenderCallback,
                             kAudioUnitScope_Input, 0, &callback_struct, sizeof callback_struct);
  if (err != noErr)
  {
    ERROR_LOG_FMT(AUDIO, "error setting audio callback");
    return false;
  }

  err = AudioUnitSetParameter(audio_unit, kHALOutputParam_Volume, kAudioUnitScope_Output, 0,
                              m_volume / 100., 0);
  if (err != noErr)
    ERROR_LOG_FMT(AUDIO, "error setting volume");

  err = AudioUnitInitialize(audio_unit);
  if (err != noErr)
  {
    ERROR_LOG_FMT(AUDIO, "error initializing audiounit");
    return false;
  }

  return true;
}

bool CoreAudioSound::SetRunning(bool running)
{
  OSStatus err;
  if (running)
  {
    err = AudioOutputUnitStart(audio_unit);
    if (err != noErr)
    {
      ERROR_LOG_FMT(AUDIO, "error starting audiounit");
      return false;
    }
  }
  else
  {
    err = AudioOutputUnitStop(audio_unit);
    if (err != noErr)
      ERROR_LOG_FMT(AUDIO, "error stopping audiounit");
  }
  return true;
}

void CoreAudioSound::SetVolume(int volume)
{
  OSStatus err;
  m_volume = volume;

  err = AudioUnitSetParameter(audio_unit, kHALOutputParam_Volume, kAudioUnitScope_Output, 0,
                              volume / 100., 0);
  if (err != noErr)
    ERROR_LOG_FMT(AUDIO, "error setting volume");
}
