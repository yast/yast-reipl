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

# File:	clients/reipl.ycp
# Package:	Configuration of reipl
# Summary:	Main file
# Authors:	Mark Hamzy <hamzy@us.ibm.com>
#
# $Id$
#
# Main file for reipl configuration. Uses all other files.
module Yast
  module ReiplDialogsInclude
    def initialize_reipl_dialogs(include_target)
      textdomain "reipl"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Reipl"

      Yast.include include_target, "reipl/helps.rb"
    end

    # Configure dialog
    # @return dialog result
    def ConfigureDialog
      ccw_map = Convert.convert(
        Ops.get(Reipl.reipl_configuration, "ccw") do
          { "device" => "", "loadparm" => "" }
        end,
        :from => "any",
        :to   => "map <string, string>"
      )
      fcp_map = Convert.convert(
        Ops.get(Reipl.reipl_configuration, "fcp") do
          {
            "device"   => "",
            "wwpn"     => "",
            "lun"      => "",
            "bootprog" => "",
            "br_lba"   => ""
          }
        end,
        :from => "any",
        :to   => "map <string, string>"
      )

      # Reipl configure dialog caption
      caption = _("Reipl Configuration")

      # Reipl configure dialog contents
      method_contents = Frame(
        _("reipl methods"),
        VBox(
          VSpacing(0.2),
          RadioButtonGroup(
            Id(:rbgroupmethods),
            VBox(
              Left(
                RadioButton(
                  Id(:useccw),
                  Opt(:notify),
                  _("&ccw"),
                  Reipl.ccw_exists
                )
              ),
              Left(
                RadioButton(
                  Id(:usefcp),
                  Opt(:notify),
                  _("&fcp"),
                  Reipl.fcp_exists
                )
              ),
              VSpacing(0.2)
            )
          )
        )
      )

      ccw_contents = Frame(
        Id(:ccw_frame),
        _("ccw parameters"),
        VBox(
          VSpacing(0.2),
          TextEntry(
            Id(:ccw_device),
            _("&Device"),
            Ops.get_string(ccw_map, "device", "")
          ),
          VSpacing(0.2),
          TextEntry(
            Id(:ccw_loadparm),
            _("&Loadparm"),
            Ops.get_string(ccw_map, "loadparm", "")
          ),
          VSpacing(0.2)
        )
      )

      fcp_contents = Frame(
        Id(:fcp_frame),
        _("fcp parameters"),
        VBox(
          VSpacing(0.2),
          TextEntry(
            Id(:fcp_device),
            _("D&evice"),
            Ops.get_string(fcp_map, "device", "")
          ),
          VSpacing(0.2),
          TextEntry(
            Id(:fcp_wwpn),
            _("&Worldwide port number"),
            Ops.get_string(fcp_map, "wwpn", "")
          ),
          VSpacing(0.2),
          TextEntry(
            Id(:fcp_lun),
            _("Lo&gical unit number"),
            Ops.get_string(fcp_map, "lun", "")
          ),
          VSpacing(0.2),
          TextEntry(
            Id(:fcp_bootprog),
            _("B&oot program selector"),
            Ops.get_string(fcp_map, "bootprog", "")
          ),
          VSpacing(0.2),
          TextEntry(
            Id(:fcp_br_lba),
            _("Boo&t record logical block address"),
            Ops.get_string(fcp_map, "br_lba", "")
          ),
          VSpacing(0.2)
        )
      )

      contents = HVSquash(
        VBox(
          method_contents,
          VSpacing(1),
          ccw_contents,
          VSpacing(1),
          fcp_contents
        )
      )

      Wizard.SetContents(
        _("reipl configuration"),
        contents,
        Ops.get_locale(@HELPS, "configure", _("help missing in helps.ycp")),
        true,
        true
      )

      UI.ChangeWidget(Id(:ccw_frame), :Enabled, Reipl.ccw_exists)
      UI.ChangeWidget(Id(:useccw), :Enabled, Reipl.ccw_exists)
      UI.ChangeWidget(Id(:fcp_frame), :Enabled, Reipl.fcp_exists)
      UI.ChangeWidget(Id(:usefcp), :Enabled, Reipl.fcp_exists)

      # @TODO
      #  UI::ChangeWidget(`id(`ccw_device), `ValidChars, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-");

      ret = nil
      while true
        ret = UI.UserInput

        # abort?
        if ret == :abort || ret == :cancel
          # Check to see if any of the data has been modified
          if Reipl.ccw_exists
            if Ops.get_string(ccw_map, "device", "") !=
                Convert.to_string(UI.QueryWidget(Id(:ccw_device), :Value))
              Reipl.modified = true
            end
            if Ops.get_string(ccw_map, "loadparm", "") !=
                Convert.to_string(UI.QueryWidget(Id(:ccw_loadparm), :Value))
              Reipl.modified = true
            end
          end

          if Reipl.fcp_exists
            if Ops.get_string(fcp_map, "device", "") !=
                Convert.to_string(UI.QueryWidget(Id(:fcp_device), :Value))
              Reipl.modified = true
            end
            if Ops.get_string(fcp_map, "wwpn", "") !=
                Convert.to_string(UI.QueryWidget(Id(:fcp_wwpn), :Value))
              Reipl.modified = true
            end
            if Ops.get_string(fcp_map, "lun", "") !=
                Convert.to_string(UI.QueryWidget(Id(:fcp_lun), :Value))
              Reipl.modified = true
            end
            if Ops.get_string(fcp_map, "bootprog", "") !=
                Convert.to_string(UI.QueryWidget(Id(:fcp_bootprog), :Value))
              Reipl.modified = true
            end
            if Ops.get_string(fcp_map, "br_lba", "") !=
                Convert.to_string(UI.QueryWidget(Id(:fcp_br_lba), :Value))
              Reipl.modified = true
            end
          end

          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next
          # Grab the data from the entry fields
          if Reipl.ccw_exists
            Ops.set(
              ccw_map,
              "device",
              Convert.to_string(UI.QueryWidget(Id(:ccw_device), :Value))
            )
            Ops.set(
              ccw_map,
              "loadparm",
              Convert.to_string(UI.QueryWidget(Id(:ccw_loadparm), :Value))
            )

            # Apparently, maps are copy on write.  We need to put the new one back into the globals.
            Ops.set(Reipl.reipl_configuration, "ccw", ccw_map)
          end

          if Reipl.fcp_exists
            Ops.set(
              fcp_map,
              "device",
              Convert.to_string(UI.QueryWidget(Id(:fcp_device), :Value))
            )
            Ops.set(
              fcp_map,
              "wwpn",
              Convert.to_string(UI.QueryWidget(Id(:fcp_wwpn), :Value))
            )
            Ops.set(
              fcp_map,
              "lun",
              Convert.to_string(UI.QueryWidget(Id(:fcp_lun), :Value))
            )
            Ops.set(
              fcp_map,
              "bootprog",
              Convert.to_string(UI.QueryWidget(Id(:fcp_bootprog), :Value))
            )
            Ops.set(
              fcp_map,
              "br_lba",
              Convert.to_string(UI.QueryWidget(Id(:fcp_br_lba), :Value))
            )

            # Apparently, maps are copy on write.  We need to put the new one back into the globals.
            Ops.set(Reipl.reipl_configuration, "fcp", fcp_map)
          end

          break
        elsif ret == :back
          break
        elsif ret == :usefcp
          next
        elsif ret == :useccw
          next
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end
  end
end
