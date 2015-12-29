# Copyright (C) 2015-2016 DragonTC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Bluetooth Modules
BLUETOOTH := libbluetooth_jni bluetooth.mapsapi bluetooth.default bluetooth.mapsapi libbt-brcm_stack audio.a2dp.default libbt-brcm_gki libbt-utils libbt-qcom_sbc_decoder libbt-brcm_bta libbt-brcm_stack libbt-vendor libbtprofile libbtdevice libbtcore bdt bdtest libbt-hci libosi ositests libbluetooth_jni net_test_osi net_test_device net_test_btcore net_bdtool net_hci bdAddrLoader

#######################
##  D R A G O N T C  ##
#######################

# Disable modules that don't work with DragonTC. Split up by arch.
DISABLE_DTC_arm :=
DISABLE_DTC_arm64 :=

# Set DISABLE_DTC based on arch
DISABLE_DTC := \
  $(DISABLE_DTC_$(TARGET_ARCH)) \
  $(LOCAL_DISABLE_DTC)

# Enable DragonTC on GCC modules. Split up by arch.
ENABLE_DTC_arm :=
ENABLE_DTC_arm64 :=

# Set ENABLE_DTC based on arch
ENABLE_DTC := \
  $(ENABLE_DTC_$(TARGET_ARCH)) \
  $(LOCAL_ENABLE_DTC)

# Enable DragonTC on current module if requested.
ifeq (1,$(words $(filter $(ENABLE_DTC),$(LOCAL_MODULE))))
  my_cc := $(CLANG)
  my_cxx := $(CLANG_CXX)
  my_clang := true
endif

# Disable DragonTC on current module if requested.
ifeq ($(my_clang),true)
  ifeq (1,$(words $(filter $(DISABLE_DTC),$(LOCAL_MODULE))))
    my_cc := $(AOSP_CLANG)
    my_cxx := $(AOSP_CLANG_CXX)
    ifeq ($(HOST_OS),darwin)
      # Darwin is really bad at dealing with idiv/sdiv. Don't use krait on Darwin.
      CLANG_CONFIG_arm_EXTRA_CFLAGS += -mcpu=cortex-a9
    else
      CLANG_CONFIG_arm_EXTRA_CFLAGS += -mcpu=krait
    endif
  else
    CLANG_CONFIG_arm_EXTRA_CFLAGS += -mcpu=krait2
  endif
endif


#################
##  P O L L Y  ##
#################

# Polly flags for use with Clang
POLLY := -O3 -mllvm -polly \
  -mllvm -polly-parallel \
  -mllvm -polly-ast-use-context \
  -mllvm -polly-vectorizer=polly \
  -mllvm -polly-opt-fusion=max \
  -mllvm -polly-opt-maximize-bands=yes \
  -mllvm -polly-run-dce

# Enable version specific Polly flags.
ifeq (1,$(words $(filter 3.7 3.8 3.9,$(LLVM_PREBUILTS_VERSION))))
  POLLY += -mllvm -polly-dependences-computeout=0 \
    -mllvm -polly-dependences-analysis-type=value-based
endif
ifeq (1,$(words $(filter 3.8 3.9,$(LLVM_PREBUILTS_VERSION))))
  POLLY += -mllvm -polly-position=after-loopopt \
    -mllvm -polly-run-inliner \
    -mllvm -polly-detect-keep-going \
    -mllvm -polly-rtc-max-arrays-per-group=40
endif

# Disable modules that dont work with Polly. Split up by arch.
DISABLE_POLLY_arm := \
  libpng \
  libLLVMCodeGen \
  libLLVMARMCodeGen\
  libLLVMScalarOpts \
  libLLVMSupport \
  libLLVMMC \
  libLLVMMCParser \
  libminui \
  libgui \
  libF77blas \
  libF77blasAOSP \
  libRSCpuRef \
  libRS \
  libjni_latinime_common_static \
  libmedia \
  libRSDriver \
  libxml2 \
  libc_freebsd \
  libc_tzcode \
  libv8
DISABLE_POLLY_arm64 := \
  libpng \
  libfuse \
  libLLVMAsmParser \
  libLLVMBitReader \
  libLLVMCodeGen \
  libLLVMInstCombine \
  libLLVMMCParser \
  libLLVMSupport \
  libLLVMSelectionDAG \
  libLLVMTransformUtils \
  libF77blas \
  libbccSupport \
  libblas \
  libRS \
  libstagefright_mpeg2ts \
  bcc_strip_attr

# Add version specific disables.
ifeq (1,$(words $(filter 3.8 3.9,$(LLVM_PREBUILTS_VERSION))))
  DISABLE_POLLY_arm64 += \
	healthd \
	libandroid_runtime \
	libblas \
	libF77blas \
	libF77blasV8 \
	libgui \
	libjni_latinime_common_static \
	libLLVMAArch64CodeGen \
	libLLVMARMCodeGen \
	libLLVMAnalysis \
	libLLVMScalarOpts \
	libLLVMCore \
	libLLVMInstrumentation \
	libLLVMipo \
	libLLVMMC \
	libLLVMSupport \
	libLLVMTransformObjCARC \
	libLLVMVectorize \
	libminui \
	libprotobuf-cpp-lite \
	libRS \
	libRSCpuRef \
	libunwind_llvm \
	libv8 \
	libvixl \
	libvterm \
	libxml2
endif

# Set DISABLE_POLLY based on arch
DISABLE_POLLY := \
  $(DISABLE_POLLY_$(TARGET_ARCH)) \
  $(DISABLE_DTC) \
  $(BLUETOOTH) \
  $(LOCAL_DISABLE_POLLY)

# Set POLLY based on DISABLE_POLLy
ifeq (1,$(words $(filter $(DISABLE_POLLY),$(LOCAL_MODULE))))
  POLLY := -Os
endif

ifeq ($(my_clang),true)
  ifndef LOCAL_IS_HOST_MODULE
    # Possible conflicting flags will be filtered out to reduce argument
    # size and to prevent issues with locally set optimizations.
    my_cflags := $(filter-out -Wall -Werror -g -O3 -O2 -Os -O1 -O0 -Og -Oz -Wextra -Weverything,$(my_cflags))
    # Enable -O3 and Polly if not blacklisted, otherwise use -Os.
    my_cflags += $(POLLY) -Qunused-arguments -Wno-unknown-warning-option -w
  endif
endif


#############
##  L T O  ##
#############

# Disable modules that don't work with Link Time Optimizations. Split up by arch.
DISABLE_LTO_arm := libLLVMScalarOpts libjni_latinime_common_static libjni_latinime adbd nit libnetd_client libblas
DISABLE_THINLTO_arm := libart libart-compiler libsigchain
DISABLE_LTO_arm64 := 
DISABLE_THINLTO_arm64 :=


# Set DISABLE_LTO and DISABLE_THINLTO based on arch
DISABLE_LTO := \
  $(DISABLE_LTO_$(TARGET_ARCH)) \
  $(DISABLE_DTC) \
  $(LOCAL_DISABLE_LTO)
DISABLE_THINLTO := \
  $(DISABLE_THINLTO_$(TARGET_ARCH)) \
  $(LOCAL_DISABLE_THINLTO)

# Enable LTO (currently disabled due to issues in linking, enable at your own risk)
ifeq ($(ENABLE_DTC_LTO),true)
  ifeq ($(my_clang),true)
    ifndef LOCAL_IS_HOST_MODULE
      ifneq ($(LOCAL_MODULE_CLASS),STATIC_LIBRARIES)
        ifneq (1,$(words $(filter $(DISABLE_LTO),$(LOCAL_MODULE))))
          ifneq (1,$(words $(filter $(DISABLE_THINLTO),$(LOCAL_MODULE))))
            my_cflags += -flto=thin -fuse-ld=gold
            my_ldflags += -flto=thin -fuse-ld=gold
          else
            my_cflags += -flto -fuse-ld=gold
            my_ldflags += -flto -fuse-ld=gold
          endif
        else
          my_cflags += -fno-lto -fuse-ld=gold
          my_ldflags += -fno-lto -fuse-ld=gold
        endif
      endif
    endif
  endif
endif
