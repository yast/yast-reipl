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

        if Reipl.IPL_from_boot_zipl == false
          @newConfiguration = Reipl.ReadState

          @oldCcwMap = Ops.get_map(@oldConfiguration, "ccw")
          @newCcwMap = Ops.get_map(@newConfiguration, "ccw")
          @oldFcpMap = Ops.get_map(@oldConfiguration, "fcp")
          @newFcpMap = Ops.get_map(@newConfiguration, "fcp")

          @different = Ops.get_string(@oldConfiguration, "method", "a") != Ops.get_string(@newConfiguration, "method", "b") ||
            Ops.get_string(@oldCcwMap, "device", "a")   != Ops.get_string(@newCcwMap, "device", "b") ||
            Ops.get_string(@oldCcwMap, "loadparm", "a") != Ops.get_string(@newCcwMap, "loadparm", "b") ||
            Ops.get_string(@oldCcwMap, "parm", "a")     != Ops.get_string(@newCcwMap, "parm", "b") ||
            Ops.get_string(@oldFcpMap, "device", "a")   != Ops.get_string(@newFcpMap, "device", "b") ||
            Ops.get_string(@oldFcpMap, "wwpn", "a")     != Ops.get_string(@newFcpMap, "wwpn", "b") ||
            Ops.get_string(@oldFcpMap, "lun", "a")      != Ops.get_string(@newFcpMap, "lun", "b") ||
            Ops.get_string(@oldFcpMap, "bootprog", "a") != Ops.get_string(@newFcpMap, "bootprog", "b") ||
            Ops.get_string(@oldFcpMap, "br_lba", "a")   != Ops.get_string(@newFcpMap, "br_lba", "b")

          Builtins.y2milestone(
            "(oldConfiguration['method']:'a' != newConfiguration['method']:'b') = %1",
            Ops.get_string(@oldConfiguration, "method", "a") != Ops.get_string(@newConfiguration, "method", "b")
          )
          Builtins.y2milestone(
            "(oldCcwMap['device']:'a' != newCcwMap['device']:'b')               = %1",
            Ops.get_string(@oldCcwMap, "device", "a") != Ops.get_string(@newCcwMap, "device", "b")
          )
          Builtins.y2milestone(
            "(oldCcwMap['loadparm']:'a' != newCcwMap['loadparm']:'b')           = %1",
            Ops.get_string(@oldCcwMap, "loadparm", "a") != Ops.get_string(@newCcwMap, "loadparm", "b")
          )
          Builtins.y2milestone(
            "(oldCcwMap['parm']:'a' != newCcwMap['parm']:'b')                   = %1",
            Ops.get_string(@oldCcwMap, "parm", "a") != Ops.get_string(@newCcwMap, "parm", "b")
          )
          Builtins.y2milestone(
            "(oldFcpMap['device']:'a' != newFcpMap['device']:'b')               = %1",
            Ops.get_string(@oldFcpMap, "device", "a") != Ops.get_string(@newFcpMap, "device", "b")
          )
          Builtins.y2milestone(
            "(oldFcpMap['wwpn']:'a' != newFcpMap['wwpn']:'b')                   = %1",
            Ops.get_string(@oldFcpMap, "wwpn", "a") != Ops.get_string(@newFcpMap, "wwpn", "b")
          )
          Builtins.y2milestone(
            "(oldFcpMap['lun']:'a' != newFcpMap['lun']:'b')                     = %1",
            Ops.get_string(@oldFcpMap, "lun", "a") != Ops.get_string(@newFcpMap, "lun", "b")
          )
          Builtins.y2milestone(
            "(oldFcpMap['bootprog']:'a' != newFcpMap['bootprog']:'b')           = %1",
            Ops.get_string(@oldFcpMap, "bootprog", "a") != Ops.get_string(@newFcpMap, "bootprog", "b")
          )
          Builtins.y2milestone(
            "(oldFcpMap['br_lba']:'a' != newFcpMap['br_lba']:'b')               = %1",
            Ops.get_string(@oldFcpMap, "br_lba", "a") != Ops.get_string(@newFcpMap, "br_lba", "b")
          )
          Builtins.y2milestone("different = %1", @different)

          Builtins.y2milestone("newConfiguration['method'] :  %1", Ops.get_string(@newConfiguration, "method", "ERROR"))
          if Ops.get_string(@newConfiguration, "method", "ERROR") == "ccw"
            Builtins.y2milestone("making ccw ipl text")
            @dev = Builtins.substring(
              Ops.get_string(@newCcwMap, "device", ""),
              4,
              4
            )

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
            @dev = Builtins.substring(
              Ops.get_string(@newFcpMap, "device", ""),
              4,
              4
            )
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
