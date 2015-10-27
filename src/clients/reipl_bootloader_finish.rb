# encoding: utf-8

# File:	reipl_bootloader_finish.ycp
#
# Module:	reIPL
#
# Authors:	Ulrich Hecht <uli@suse.de>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
module Yast
  class ReiplBootloaderFinishClient < Client
    def main
      # YaST finish client returns (map) $[
      #     "different" : (boolean) whether changed,
      #     "ipl_msg"   : (string) localized message,
      # ]

      Yast.import "Arch"
      Yast.import "Reipl"

      textdomain "reipl"

      @different = true
      @ipl_msg = ""

      # Other architectures do not support it
      if Arch.s390
        @oldConfiguration = Reipl.ReadState

        if !Reipl.IPL_from_boot_zipl
          @newConfiguration = Reipl.ReadState

          @oldCcwMap = Ops.get_map(@oldConfiguration, "ccw")
          @newCcwMap = Ops.get_map(@newConfiguration, "ccw")
          @oldFcpMap = Ops.get_map(@oldConfiguration, "fcp")
          @newFcpMap = Ops.get_map(@newConfiguration, "fcp")

          ccw_different = ["device", "loadparm", "parm"].any? do |param|
            # TODO: why two nils are different?
            res = @oldCcwMap[param].nil? || @newCcwMap[param].nil? || @oldCcwMap[param] != @newCcwMap[param]
            Builtins.y2milestone "ccw comparison for '#{param}' is different?: #{res}"
            res
          end
          fcp_different = ["device", "wwpn", "lun", "bootprog", "br_lba"].any? do |param|
            # TODO: why two nils are different?
            res = @oldFcpMap[param].nil? || @newFcpMap[param].nil? || @oldFcpMap[param] != @newFcpMap[param]
            Builtins.y2milestone "fcp comparison for '#{param}' is different?: #{res}"
            res
          end
          # zkvm require change of IPL (bnc#943582)
          zkvm = Yast::WFM.Execute(".local.bash", "egrep 'Control Program: KVM' /proc/cpuinfo") == 0
          @different = ccw_different || fcp_different || zkvm
          Builtins.y2milestone("different = %1", @different)

          Builtins.y2milestone("newConfiguration['method'] :  %1", Ops.get_string(@newConfiguration, "method", "ERROR"))
          if Ops.get_string(@newConfiguration, "method", "ERROR") == "ccw"
            Builtins.y2milestone("making ccw ipl text")
            @dev = Builtins.substring(Ops.get_string(@newCcwMap, "device", ""), 4, 4)

            # TRANSLATORS: part of a shutdown message
            # %1 is replaced with a device name
            # Newline at the end is required
            @ipl_msg = Builtins.sformat(
              _(
                "\n" +
                  "After shutdown, reload the system\n" +
                  "with an IPL from DASD '%1'.\n"
              ),
              @dev
            )
          elsif Ops.get_string(@newConfiguration, "method", "ERROR") == "fcp"
            Builtins.y2milestone("making fcp ipl text")
            @dev = Builtins.substring(Ops.get_string(@newFcpMap, "device", ""), 4, 4)
            @wwpn = Ops.get_string(@newFcpMap, "wwpn", "")
            @lun = Ops.get_string(@newFcpMap, "lun", "")

            # TRANSLATORS: part of a shutdown message
            # %1 is replaced with a FCP name
            # %2 is replaced with a WWPN name
            # %3 is replaced with a LUN name
            # Newline at the end is required
            @ipl_msg = Builtins.sformat(
              _(
                "\n" +
                  "After shutdown, reload the system\n" +
                  "with an IPL from FCP '%1'\n" +
                  "with WWPN '%2'\n" +
                  "and LUN '%3'.\n"
              ),
              @dev,
              @wwpn,
              @lun
            )
          else
            Builtins.y2warning("making generic ipl text for unknown method")
            @ipl_msg = Builtins.sformat(
              _(
                "\n" +
                  "After shutdown, reload the system \n" +
                  "with an IPL from the device \n" +
                  "that contains /boot"
              )
            )
          end
        end
      end

      Builtins.y2milestone("Configuration (reIPL) has been changed: %1", @different)
      Builtins.y2milestone("Configuration (reIPL) generated shutdown dialog box message: %1", @ipl_msg)

      @ret = { "different" => @different, "ipl_msg" => @ipl_msg }

      Builtins.y2milestone("ret = %1", @ret)

      deep_copy(@ret)
    end
  end
end

Yast::ReiplBootloaderFinishClient.new.main
