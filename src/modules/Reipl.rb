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

# File:	modules/Reipl.ycp
# Package:	Configuration of reipl
# Summary:	Reipl settings, input and output functions
# Authors:	Mark Hamzy <hamzy@us.ibm.com>
#
# $Id$
#
# Representation of the configuration of reipl.
# Input and output routines.
require "yast"

module Yast
  class ReiplClass < Module
    def main
      textdomain "reipl"

      Yast.import "Summary"
      Yast.import "FileUtils"

      # Data was modified?
      @modified = false


      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")

      # Settings: Define all variables needed for configuration of reipl
      @reipl_configuration = {}
      # global map <string, any> reipl_configuration = $[
      #	"method":	"ccw",
      #	"ccw":		$[
      #			"device":	"0.0.4711",
      #			"loadparm":	"",
      #			"parm": 	"" /* SLES 11 and z/VM only */
      #		],
      #	"fcp":		$[
      #			"device":	"0.0.4711",
      #			"wwpn":		"0x5005076303004711",
      #			"lun":		"0x4711000000000000",
      #			"bootprog":	"0",
      #			"br_lba":	"0"
      #		]
      #];

      @reipl_directory = "/sys/firmware/reipl"
      @ccw_directory = @reipl_directory + "/ccw"
      @fcp_directory = @reipl_directory + "/fcp"
      @nss_directory = @reipl_directory + "/nss"
      @ccw_exists = FileUtils.IsDirectory(@ccw_directory)
      @fcp_exists = FileUtils.IsDirectory(@fcp_directory)
      @nss_exists = FileUtils.IsDirectory(@fcp_directory)
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call if @AbortFunction
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    # Indicate that the data was modified
    def SetModified
      Builtins.y2debug("Reipl::SetModified")
      @modified = true
      nil
    end

    # Check to see if reipl is supported by the kernel.
    # @return [Boolean] true if support exists.
    # Returns the reipl configuration passed in with what it should be for the detected
    # boot partition.
    # @param [Hash{String => Object}] configuration an old configuration.
    # @return a map of the new target configuration.
    def IPL_from_boot_zipl
      # get target information
      result = Yast::SCR.Execute(path(".target.bash_output"), "chreipl node /boot/zipl")
      return result["exit"] == 0
    end

    # Read all reipl settings
    # @return [Hash{String => Object}] of settings
    def ReadState
      configuration = {}
        Builtins.y2milestone("ReadState: The beginngn")
      Ops.set(configuration, "ccw", { "device" => "", "loadparm" => "", "parm" => "" })
      Ops.set(configuration, "fcp", { "device"   => "", "wwpn"     => "", "lun"      => "", "bootprog" => "", "br_lba"   => "", "bootparms"	=> "" })
      Ops.set(configuration, "nss", { "name" => "", "loadparm" => "", "parm" => "" })

      result = Yast::SCR.Execute(path(".target.bash_output"), "lsreipl")
      raise "Calling lsreipl failed with #{result["stderr"]}" unless result["exit"].zero?

      lsreipl_lines = result["stdout"].split("\n")
      type = lsreipl_lines[0][/ccw$|fcp$|node$/]
      if type == "ccw"
         ccw_map = configuration["ccw"]
         ccw_map["device"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[1][/[0-3]\.[0-3]\.[\h.]*$/]), "\n\r") if lsreipl_lines[1]
         ccw_map["loadparm"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[2][/".*"$/]), "\n\r\"") if lsreipl_lines[2]
         ccw_map["parm"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[3][/".*"$/]), "\n\r\"") if lsreipl_lines[3]
         Ops.set(configuration, "ccw", ccw_map)
      end
      if type == "fcp"
         fcp_map = configuration["fcp"]
         ccw_map["wwpm"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[1][/[x\h]*$/]), "\n\r") if lsreipl_lines[1]
         ccw_map["lun"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[2][/[x\h]*$/]), "\n\r") if lsreipl_lines[2]
         ccw_map["device"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[3][/[0-3]\.[0-3]\.[\h.]*$/]), "\n\r") if lsreipl_lines[3]
         ccw_map["bootprog"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[4][/[0-9]*$/]), "\n\r") if lsreipl_lines[4]
         ccw_map["br_lbr"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[5][/[0-9]*$/]), "\n\r") if lsreipl_lines[5]
         ccw_map["bootparms"] = Builtins.deletechars(Convert.to_string(lsreipl_lines[6][/".*"*$/]), "\n\r\"") if lsreipl_lines[6]
         Ops.set(configuration, "fcp", fcp_map)
      end

      configuration["method"] = type

      deep_copy(configuration)
    end

    # Read all reipl settings
    # @return true on success
    def Read
      configuration = ReadState()

      @reipl_configuration = deep_copy(configuration) if configuration

      return false if Abort()
      @modified = false
      true
    end

    # Write all reipl setting to the firmware
    # @param [Hash{String => Object}] configuration the current configuration.
    # @return true on success
    def WriteState(configuration)
      configuration = deep_copy(configuration)
      rc = true
      result = nil

      if Ops.get(configuration, "method") != nil &&
          Ops.get_string(configuration, "method", "unknown_disk_type") !=
            "unknown_disk_type"

	type = Ops.get_string(configuration, "method")
        Builtins.y2milestone("Reipl::WriteState: writing out method %1", type)
      end

      if type == "ccw"
        ccw_map = Ops.get_map(configuration, "ccw")

        if ccw_map != nil

	  device = Ops.get_string(ccw_map, "device", "???")
	  loadparm = Ops.get_string(ccw_map, "loadparm", "???")

        else
          Builtins.y2error("Reipl::WriteState: ccw_map is nil!")

          rc = false
        end
      end

      if type == "fcp"
        fcp_map = Ops.get_map(configuration, "fcp")

        if fcp_map != nil
          Builtins.y2milestone("Reipl::WriteState: fcp_map device is now \"%1\"", Ops.get_string(fcp_map, "device", "???"))
          Builtins.y2milestone("Reipl::WriteState: fcp_map wwpn is now \"%1\"", Ops.get_string(fcp_map, "wwpn", "???"))
          Builtins.y2milestone("Reipl::WriteState: fcp_map lun is now \"%1\"", Ops.get_string(fcp_map, "lun", "???"))
          Builtins.y2milestone("Reipl::WriteState: fcp_map bootprog is now \"%1\"", Ops.get_string(fcp_map, "bootprog", "???"))
          Builtins.y2milestone("Reipl::WriteState: fcp_map br_lba is now \"%1\"", Ops.get_string(fcp_map, "br_lba", "???"))

	  device = Ops.get_string(fcp_map, "device") + " " + Ops.get_string(fcp_map, "wwpn") + " " + Ops.get_string(fcp_map, "lun")
	  loadparm = Ops.get_string(fcp_map, "loadparm", "???")

          Builtins.y2milestone("FCP Device %1, loadparm %2 %1", device, loadparm)

        else
          Builtins.y2error("Reipl::Write: fcp_map is nil!")

          rc = false
        end
      end
      if type == "nss"
         nss_map = Ops.get_map(configuration, "nss")
	 if nss_map != nil
	 	device = Ops.get_string(fcp_map, "name")
		loadparm = ""
	 end
      end
      # now type, device, loadparm contain all what is needed to call chreipl
      chreiplCmd = "chreipl " + type  + " " + device
      if loadparm != ""
      	chreiplCmd << " -L " + loadparm
      end
      Builtins.y2milestone("Executing %1", chreiplCmd)
      result = Convert.to_map(SCR.Execute(path(".target.bash_output"), chreiplCmd))
      if Ops.get_integer(result, "exit", -1) != 0
        Builtins.y2error( "Error: Calling chreipl fails with code %1 and output %2", Ops.get_integer(result, "exit", -1), Ops.get_string(result, "stderr", ""))

        rc = false
      end

      rc
    end

    # Write all reipl settings
    # @return true on success
    def Write
      rc = WriteState(@reipl_configuration)

      return false if Abort()

      rc
    end

    # Get all reipl settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      imported = {}

      if Ops.get(settings, "ccw") != nil
        ccwIn = Ops.get_map(settings, "ccw", {})
        ccwOut = { "device" => "", "loadparm" => "", "parm" => "" } # SLES 11 and z/VM only

        if Ops.get(ccwIn, "device") != nil
          Ops.set(ccwOut, "device", Ops.get(ccwIn, "device"))
        end
        if Ops.get(ccwIn, "loadparm") != nil
          Ops.set(ccwOut, "loadparm", Ops.get(ccwIn, "loadparm"))
        end
        # SLES 11 and z/VM only
        if Ops.get(ccwIn, "parm") != nil
          Ops.set(ccwOut, "parm", Ops.get(ccwIn, "parm"))
        end

        Ops.set(imported, "ccw", ccwOut)
      end

      if Ops.get(settings, "fcp") != nil
        fcpIn = Ops.get_map(settings, "fcp", {})
        fcpOut = {
          "device"   => "",
          "wwpn"     => "",
          "lun"      => "",
          "bootprog" => "",
          "br_lba"   => ""
        }

        if Ops.get(fcpIn, "device") != nil
          Ops.set(fcpOut, "device", Ops.get(fcpIn, "device"))
        end
        if Ops.get(fcpIn, "wwpn") != nil
          Ops.set(fcpOut, "wwpn", Ops.get(fcpIn, "wwpn"))
        end
        if Ops.get(fcpIn, "lun") != nil
          Ops.set(fcpOut, "lun", Ops.get(fcpIn, "lun"))
        end
        if Ops.get(fcpIn, "bootprog") != nil
          Ops.set(fcpOut, "bootprog", Ops.get(fcpIn, "bootprog"))
        end
        if Ops.get(fcpIn, "br_lba") != nil
          Ops.set(fcpOut, "br_lba", Ops.get(fcpIn, "br_lba"))
        end

        Ops.set(imported, "fcp", fcpOut)
      end

      @reipl_configuration = deep_copy(imported)

      true
    end

    # Dump the reipl settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      deep_copy(@reipl_configuration)
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      summary = ""
      status = nil
      found = nil

      summary = Summary.AddHeader(summary, _("Configured reipl methods"))

      summary = Summary.OpenList(summary)

      found = Ops.get_map(@reipl_configuration, "ccw")
      if found != nil
        if Ops.get(@reipl_configuration, "method") == "ccw"
          status = _("The method ccw is configured and being used.")
        else
          status = _("The method ccw is configured.")
        end
      else
        status = _("The method ccw is not supported.")
      end

      summary = Summary.AddListItem(summary, status)

      found = Ops.get_map(@reipl_configuration, "fcp")
      if found != nil
        if Ops.get(@reipl_configuration, "method") == "fcp"
          status = _("The method fcp is configured and being used.")
        else
          status = _("The method fcp is configured.")
        end
      else
        status = _("The method fcp is not supported.")
      end

      summary = Summary.AddListItem(summary, status)

      summary = Summary.CloseList(summary)

      [summary, []]
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      { "install" => [], "remove" => [] }
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :SetModified, :type => "void ()"
    publish :variable => :reipl_configuration, :type => "map <string, any>"
    publish :variable => :reipl_directory, :type => "string"
    publish :variable => :ccw_directory, :type => "string"
    publish :variable => :fcp_directory, :type => "string"
    publish :variable => :nss_directory, :type => "string"
    publish :variable => :ccw_exists, :type => "boolean"
    publish :variable => :fcp_exists, :type => "boolean"
    publish :variable => :nss_exists, :type => "boolean"
    publish :function => :IPL_from_boot_zipl, :type => "boolean ()"
    publish :function => :ReadState, :type => "map <string, any> ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :WriteState, :type => "boolean (map <string, any>)"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  Reipl = ReiplClass.new
  Reipl.main
end
