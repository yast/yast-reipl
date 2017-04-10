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

      # Other architectures do not support it
      Reipl.IPL_from_boot_zipl if Arch.s390

      # result is always same, as when chreipl failed we just report problem there
      # previously we suggest how to manually switch IPL but it probably also
      # won't boot
      # see bsc#976609 comment#59
      ret = { "different" => false, "ipl_msg" => "" }

      Builtins.y2milestone("ret = %1", ret)

      ret
    end
  end
end

Yast::ReiplBootloaderFinishClient.new.main
