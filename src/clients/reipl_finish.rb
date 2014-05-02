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

        # FIXME almost same code as reipl_bootloader_finish and this client is not called at all now
        if Reipl.IPL_from_boot_zipl

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

          @different = ccw_different || fcp_different
          Builtins.y2milestone("different = %1", @different)
        end

        Builtins.y2milestone("Configuration (reIPL) has been changed: %1", @different)
      end

      @different
    end
  end
end

Yast::ReiplFinishClient.new.main
