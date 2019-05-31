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

# File:	include/reipl/wizards.ycp
# Package:	Configuration of reipl
# Summary:	Wizards definitions
# Authors:	Mark Hamzy <hamzy@us.ibm.com>
#
# $Id$
module Yast
  module ReiplWizardsInclude
    def initialize_reipl_wizards(include_target)
      Yast.import "UI"

      textdomain "reipl"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "reipl/complex.rb"
      Yast.include include_target, "reipl/dialogs.rb"
    end

    # Add a configuration of reipl
    # @return sequence result
    def ConfigureSequence
      aliases = { "config" => lambda { ConfigureDialog() } }

      sequence = {
        "ws_start" => "config",
        "config"   => { :abort => :abort, :next => :next }
      }

      Sequencer.Run(aliases, sequence)
    end

    # Main workflow of the reipl configuration
    # @return sequence result
    def MainSequence
      aliases = { "configure" => [lambda { ConfigureSequence() }, true] }

      sequence = {
        "ws_start"  => "configure",
        "configure" => { :abort => :abort, :next => :next }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of reipl
    # @return sequence result
    def ReiplSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("org.openSUSE.YaST.Reipl")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of reipl but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def ReiplAutoSequence
      # Initialization dialog caption
      caption = _("Reipl Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
