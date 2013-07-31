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

# File:	include/reipl/complex.ycp
# Package:	Configuration of reipl
# Summary:	Dialogs definitions
# Authors:	Mark Hamzy <hamzy@us.ibm.com>
#
# $Id$
module Yast
  module ReiplComplexInclude
    def initialize_reipl_complex(include_target)
      Yast.import "UI"

      textdomain "reipl"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "Confirm"
      Yast.import "Reipl"


      Yast.include include_target, "reipl/helps.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      Reipl.Modified
    end

    # Return if we should really abort or not.
    # @return true if we should abort
    def ReallyAbort
      !Reipl.Modified || Popup.ReallyAbort(true)
    end

    # Return the abort status
    # @return ture if we should abort
    def PollAbort
      UI.PollInput == :abort
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      # Reipl::AbortFunction = PollAbort;
      return :abort if !Confirm.MustBeRoot
      ret = Reipl.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      # Reipl::AbortFunction = PollAbort;
      ret = Reipl.Write
      ret ? :next : :abort
    end
  end
end
