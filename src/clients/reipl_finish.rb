# encoding: utf-8

# File:	reipl_finish.ycp
#
# Module:	reIPL
#
# Authors:	Ulrich Hecht <uli@suse.de>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
module Yast
  class ReiplFinishClient < Client
    def main
      # YaST finish client returns (boolean) whether configuration
      # has been changed (true/false)

      Yast.import "Arch"
      Yast.import "Reipl"

      @different = true

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
            Ops.get_string(@oldCcwMap, "device", "a") != Ops.get_string(@newCcwMap, "device", "b") ||
            Ops.get_string(@oldCcwMap, "loadparm", "a") != Ops.get_string(@newCcwMap, "loadparm", "b") ||
            Ops.get_string(@oldCcwMap, "parm", "a") != Ops.get_string(@newCcwMap, "parm", "b") ||
            Ops.get_string(@oldFcpMap, "device", "a") != Ops.get_string(@newFcpMap, "device", "b") ||
            Ops.get_string(@oldFcpMap, "wwpn", "a") != Ops.get_string(@newFcpMap, "wwpn", "b") ||
            Ops.get_string(@oldFcpMap, "lun", "a") != Ops.get_string(@newFcpMap, "lun", "b") ||
            Ops.get_string(@oldFcpMap, "bootprog", "a") != Ops.get_string(@newFcpMap, "bootprog", "b") ||
            Ops.get_string(@oldFcpMap, "br_lba", "a") != Ops.get_string(@newFcpMap, "br_lba", "b")

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
        end

        Builtins.y2milestone("Configuration (reIPL) has been changed: %1", @different)
      end

      @different
    end
  end
end

Yast::ReiplFinishClient.new.main
