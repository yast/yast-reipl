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

# File:	clients/inst_reiplauto.ycp
# Package:	Automatic configuration of reipl
# Summary:	Main file
# Authors:	Mark Hamzy <hamzy@us.ibm.com>
#
# $Id$
#
# Main file for reipl configuration. Uses all other files.
module Yast
  class InstReiplautoClient < Client
    def main
      #**
      # <h3>Configuration of reipl</h3>

      textdomain "reipl"

      Yast.import "Reipl"
      Yast.import "GetInstArgs"
      Yast.import "Mode"
      Yast.import "Wizard"
      Yast.import "FileUtils"
      Yast.import "Confirm"
      Yast.import "Storage"
      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("inst_reiplauto started")

      if !Reipl.SanityCheck
        Builtins.y2milestone("SanityCheck failed!")
        return :cancel
      end

      @args = GetInstArgs.argmap

      if Ops.get_string(@args, "first_run", "yes") != "no"
        Ops.set(@args, "first_run", "yes")
      end

      Wizard.HideAbortButton if Mode.mode == "firstboot"

      @rc = true

      @configuration = Reipl.ReadState

      if @configuration != nil
        @configuration = Reipl.ModifyReiplWithBootPartition(@configuration)

        if @configuration != nil
          Reipl.WriteState(@configuration)
        else
          Builtins.y2error("Could not modify reipl configuration")
        end
      else
        Builtins.y2error("Could not read reipl configuration")
      end

      # Finish
      Builtins.y2milestone("inst_reiplauto finished")
      Builtins.y2milestone("----------------------------------------")

      :next 

      # EOF
    end
  end
end

Yast::InstReiplautoClient.new.main
