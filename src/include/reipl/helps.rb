# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/reipl/helps.ycp
# Package:	Configuration of reipl
# Summary:	Help texts of all the dialogs
# Authors:	Mark Hamzy <hamzy@us.ibm.com>
#
# $Id$
module Yast
  module ReiplHelpsInclude
    def initialize_reipl_helps(include_target)
      textdomain "reipl"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"      => _(
          "<p><b><big>Initializing reipl Configuration</big></b><br>\n</p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"     => _(
          "<p><b><big>Saving reipl Configuration</big></b><br>\n</p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs whether it is safe to do so.\n" +
              "</p>\n"
          ),
        # Configure dialog help 1
        "configure" => _(
          "<p><b><big>s390 reIPL Configuration</big></b></p>"
        ) +
          # Configure dialog help 2
          _(
            "<p>Choose one of the methods for rebooting your machine with the radio buttons\n" +
              "listed inside <b>reipl methods</b>. Depending on what your machine supports,\n" +
              "choose between CCW (channel command word) devices and SCSI devices,\n" +
              "which are attached through zFCP (fibre channel protocol). Then fill out the\n" +
              "necessary parameter entry fields for the respective method.</p>\n"
          ) +
          # Configure dialog help 3
          _(
            "<p>The <b>device</b> must be a valid device bus ID with lower case letters\n" +
              "in a sysfs compatible format 0.<i>&lt;subchannel set ID&gt;</i>.<i>&lt;device ID&gt;</i>,\n" +
              "such as 0.0.5c51. Depending on the chosen method, this can either refer to a DASD or to\n" +
              "an FCP adapter.</p>"
          ) +
          # Configure dialog help 4
          _(
            "<p>The <b>loadparm</b> must be a maximum of 8 characters and selects a boot\n" +
              "configuration from the menu of the zipl bootloader. Use one blank character\n" +
              "to select the default configuration.</p>"
          ) +
          # Configure dialog help 5
          _(
            "<p>The <b>worldwide port number</b> (WWPN) must be entered with lowercase\nletters as a 16-digit hex value, such as 0x5005076300c40e5a.</p>\n"
          ) +
          # Configure dialog help 6
          _(
            "<p>The <b>logical unit number</b> (LUN) must be entered with lowercase letters\nas a 16-digit hex value with all trailing zeros, such as 0x52ca000000000000.</p>"
          ) +
          # Configure dialog help 7
          _(
            "<p>The <b>boot program selector</b> must be a non-negative integer choosing\n" +
              "a boot configuration from the menu of the zipl bootloader. Use 0 to select\n" +
              "the default configuration.</p>"
          ) +
          # Configure dialog help 8
          _(
            "<p>The <b>boot record logical block address</b> (LBA) specifies the master\nboot record and is currently always 0.</p>"
          ) +
          # Configure dialog help 9
          _(
            "<p>After confirmation of this dialog, you may trigger a reboot, e.g. by shutdown,\nand the system will automatically restart from your specified device.</p>"
          )
      } 

      # EOF
    end
  end
end
