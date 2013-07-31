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

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "FileUtils"
      Yast.import "Confirm"
      Yast.import "Popup"
      Yast.import "Storage"

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

      @reipl_directory = Ops.add(FindSysfsRoot(), "/firmware/reipl")
      @ccw_directory = Ops.add(@reipl_directory, "/ccw")
      @fcp_directory = Ops.add(@reipl_directory, "/fcp")
      @ccw_exists = FileUtils.IsDirectory(@ccw_directory) != nil
      @fcp_exists = FileUtils.IsDirectory(@fcp_directory) != nil
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
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

    # Find where sysfs has been mounted.
    # @return [String] the root
    def FindSysfsRoot
      ret = nil
      mounts = nil

      mounts = Convert.convert(
        SCR.Read(path(".etc.mtab")),
        :from => "any",
        :to   => "list <map>"
      )

      Builtins.foreach(mounts) do |mount|
        Builtins.y2debug("FindSysfsRoot: mount = %1", mount)
        if ret == nil && Ops.get_string(mount, "vfstype", "ERROR") == "sysfs" &&
            Ops.get_string(mount, "spec", "ERROR") == "sysfs"
          ret = Ops.get_string(mount, "file")
        end
      end

      if ret == nil
        Builtins.y2error("FindSysfsRoot: after all this, ret is still nil!")

        # Note: This likely won't work so you need to check the results of calls using what we
        # are returning now.
        ret = "/sys"
      end

      Builtins.y2milestone("FindSysfsRoot: returning %1", ret)

      ret
    end

    # Check to see if reipl is supported by the kernel.
    # @return [Boolean] true if support exists.
    def SanityCheck
      # @TBD The following is broken during install since the id command is missing
      # bash-3.1# find `echo $PATH | tr ':' ' '` -name id
      #	if (!Confirm::MustBeRoot ()) {
      #		y2error ("User must be root!");
      #	}

      if !FileUtils.IsDirectory(@reipl_directory)
        Builtins.y2error("Directory does not exist: %1", @reipl_directory)
        return false
      end

      if !@ccw_exists && !@fcp_exists
        Builtins.y2error(
          "Either ccw or fcp must exist under %1",
          @reipl_directory
        )
        return false
      end

      if @ccw_exists
        if !FileUtils.Exists(Ops.add(@ccw_directory, "/device"))
          Builtins.y2error("Missing device under %1", @ccw_directory)
          return false
        end
        if !FileUtils.Exists(Ops.add(@ccw_directory, "/loadparm"))
          Builtins.y2error("Missing loadparm under %1", @ccw_directory)
          return false
        end 
        # don't check for "parm" since it might not be there under zLPAR
      end

      if @fcp_exists
        if !FileUtils.Exists(Ops.add(@fcp_directory, "/device"))
          Builtins.y2error("Missing device under %1", @fcp_directory)
          return false
        end
        if !FileUtils.Exists(Ops.add(@fcp_directory, "/wwpn"))
          Builtins.y2error("Missing wwpn under %1", @fcp_directory)
          return false
        end
        if !FileUtils.Exists(Ops.add(@fcp_directory, "/lun"))
          Builtins.y2error("Missing lun under %1", @fcp_directory)
          return false
        end
        if !FileUtils.Exists(Ops.add(@fcp_directory, "/bootprog"))
          Builtins.y2error("Missing bootprog under %1", @fcp_directory)
          return false
        end
        if !FileUtils.Exists(Ops.add(@fcp_directory, "/br_lba"))
          Builtins.y2error("Missing br_lba under %1", @fcp_directory)
          return false
        end
      end

      if !FileUtils.Exists(Ops.add(@reipl_directory, "/reipl_type"))
        Builtins.y2error("Missing reipl_type under %1", @reipl_directory)
        return false
      end

      true
    end

    # Returns the parameters of the boot partition that was found where the
    # MBR was located.
    # @return a list of parameters
    def FindBootPartition
      uParts = nil
      fError = false
      command = nil
      result = nil

      mp = Storage.GetMountPoints

      mountdata_boot = Ops.get_list(mp, "/boot", Ops.get_list(mp, "/", []))
      Builtins.y2milestone("mountdata_boot %1", mountdata_boot)
      boot_device = Ops.get_string(mountdata_boot, 0, "")

      # Examples: /dev/dasda2 or /dev/sda3
      Builtins.y2milestone(
        "FindBootPartition: BootPartitionDevice = %1",
        boot_device
      )

      # Examples: dasda2 or sda3
      fullDisk = Builtins.substring(boot_device, 5)

      Builtins.y2milestone("FindBootPartition: fullDisk = %1", fullDisk)

      if Builtins.substring(fullDisk, 0, 4) == "dasd"
        disk = nil
        #   fullDisk might be a full block device or just a partition on such a
        #   block device. If it is a partition we have to get rid of the suffix
        #   specifying the partition in order to get the containing block device.
        #   This device could have thousands of block devices, which is not uncommon
        #   on s390. In such a case the devices would have names such as "dasdaab" or
        #   "dasdaab1."
        split = Builtins.regexptokenize(fullDisk, "^(dasd)([a-z]*)([0-9]*)$")

        if split == nil || Builtins.size(split) != 3
          Builtins.y2error(
            "FindBootPartition: Could not regexptokenize fullDisk, split = %1",
            split
          )

          fError = true
        else
          disk = Ops.add(Ops.get(split, 0, ""), Ops.get(split, 1, ""))
        end

        Builtins.y2milestone(
          "FindBootPartition: found that the MBR uses dasd (%1)",
          disk
        )

        if disk != nil
          # bash-3.1# readlink -m /sys/block/dasda/device
          # /sys/devices/css0/0.0.0006/0.0.4dcf
          command = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("/usr/bin/readlink -n -m ", FindSysfsRoot()),
                "/block/"
              ),
              disk
            ),
            "/device"
          )
          Builtins.y2milestone("Executing %1", command)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), command)
          )

          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "FindBootPartition: Execute errors and returns %1",
              Ops.get_integer(result, "exit", -1)
            )
            Builtins.y2error(
              "FindBootPartition: Execute stdout is \"%1\"",
              Ops.get_string(result, "stdout", "")
            )
            Builtins.y2error(
              "FindBootPartition: Execute stderr is \"%1\"",
              Ops.get_string(result, "stderr", "")
            )

            fError = true
          end

          Builtins.y2milestone("FindBootPartition: result = %1", result)

          readlinkParts = nil

          readlinkParts = Builtins.splitstring(
            Ops.get_string(result, "stdout", ""),
            "/"
          )

          Builtins.y2milestone(
            "FindBootPartition: readlinkParts = %1",
            readlinkParts
          )

          if Ops.less_than(Builtins.size(readlinkParts), 1)
            Builtins.y2error(
              "FindBootPartition: readlinkParts size is unexpected %1",
              readlinkParts
            )

            fError = true
          end

          ccwDevice = Ops.get(
            readlinkParts,
            Ops.subtract(Builtins.size(readlinkParts), 1),
            ""
          )

          uParts = ["ccw", ccwDevice] if !fError
        end
      elsif Builtins.substring(fullDisk, 0, 2) == "sd"
        disk = nil
        #   fullDisk might be a full block device or just a partition on such a
        #   block device. If it is a partition we have to get rid of the suffix
        #   specifying the partition in order to get the containing block device.
        #   This device could have thousands of block devices, which is not uncommon
        #   on s390. In such a case the devices would have names such as "sdaab" or
        #   "sdaab1."
        split = Builtins.regexptokenize(fullDisk, "^(sd)([a-z]*)([0-9]*)$")

        if split == nil || Builtins.size(split) != 3
          Builtins.y2error(
            "FindBootPartition: Could not regexptokenize fullDisk, split = %1",
            split
          )

          fError = true
        else
          disk = Ops.add(Ops.get(split, 0, ""), Ops.get(split, 1, ""))
        end

        if disk != nil
          Builtins.y2milestone(
            "FindBootPartition: found that the MBR uses SCSI (%1)",
            disk
          )

          deviceDirectory = Ops.add(
            Ops.add(Ops.add(FindSysfsRoot(), "/block/"), disk),
            "/device/"
          )

          # bash-3.1# cat /sys/block/sda/device/hba_id
          # 0.0.1734
          hbaId = Convert.to_string(
            SCR.Read(path(".target.string"), Ops.add(deviceDirectory, "hba_id"))
          )

          # bash-3.1# cat /sys/block/sda/device/wwpn
          # 0x500507630300c562
          wwpn = Convert.to_string(
            SCR.Read(path(".target.string"), Ops.add(deviceDirectory, "wwpn"))
          )

          # bash-3.1# cat /sys/block/sda/device/fcp_lun
          # 0x401040eb00000000
          fcpLun = Convert.to_string(
            SCR.Read(
              path(".target.string"),
              Ops.add(deviceDirectory, "fcp_lun")
            )
          )

          Builtins.y2milestone("FindBootPartition: hbaId  = %1", hbaId)
          Builtins.y2milestone("FindBootPartition: wwpn   = %1", wwpn)
          Builtins.y2milestone("FindBootPartition: fcpLun = %1", fcpLun)

          hbaId = Builtins.deletechars(hbaId, "\n ")
          wwpn = Builtins.deletechars(wwpn, "\n ")
          fcpLun = Builtins.deletechars(fcpLun, "\n ")

          if hbaId == nil || Builtins.size(hbaId) == 0
            Builtins.y2error("FindBootPartition: hbaId is empty!")
            fError = true
          end
          if wwpn == nil || Builtins.size(wwpn) == 0
            Builtins.y2error("FindBootPartition: wwpn is empty!")
            fError = true
          end
          if fcpLun == nil || Builtins.size(fcpLun) == 0
            Builtins.y2error("FindBootPartition: fcpLun is empty!")
            fError = true
          end

          uParts = ["zfcp", hbaId, wwpn, fcpLun] if !fError
        end
      else
        Builtins.y2error(
          "FindBootPartition: Unexpected format \"%1\"",
          fullDisk
        )
      end

      Builtins.y2milestone("FindBootPartition: returning uParts = %1", uParts)

      deep_copy(uParts)
    end

    # Returns the reipl configuration passed in with what it should be for the detected
    # boot partition.
    # @param [Hash{String => Object}] configuration an old configuration.
    # @return a map of the new target configuration.
    def ModifyReiplWithBootPartition(configuration)
      configuration = deep_copy(configuration)
      # get target information
      uParts = FindBootPartition()

      if uParts == nil
        Builtins.y2error("ModifyReiplWithBootPartition: uParts is nil")
      end

      fCCW = false
      fFCP = false

      if Builtins.size(uParts) == 2
        if Ops.get(uParts, 0, "") == "ccw"
          fCCW = true
        else
          Builtins.y2error(
            "ModifyReiplWithBootPartition: size of uParts is 2, but first word is not ccw!"
          )
        end
      elsif Builtins.size(uParts) == 4
        if Ops.get(uParts, 0, "") == "zfcp"
          fFCP = true
        else
          Builtins.y2error(
            "ModifyReiplWithBootPartition: size of uParts is 4, but format is not what we expect"
          )
        end
      else
        Builtins.y2error(
          "ModifyReiplWithBootPartition: size of uParts is not 2 or 4"
        )
      end

      if fCCW
        Ops.set(configuration, "method", "ccw")
        ccw_map = Ops.get_map(configuration, "ccw")

        Ops.set(ccw_map, "device", Ops.get(uParts, 1, ""))
        Ops.set(ccw_map, "loadparm", "")
        #ccw_map["parm"] = ""; /* SLES 11 and z/VM only */ // read only
        Ops.set(configuration, "ccw", ccw_map)
        Builtins.y2milestone("ModifyReiplWithBootPartition: modified ccw map")
      elsif fFCP
        Ops.set(configuration, "method", "fcp")
        fcp_map = Ops.get_map(configuration, "fcp")

        Ops.set(fcp_map, "device", Ops.get(uParts, 1, ""))
        Ops.set(fcp_map, "wwpn", Ops.get(uParts, 2, ""))
        Ops.set(fcp_map, "lun", Ops.get(uParts, 3, ""))
        Ops.set(fcp_map, "bootprog", "0")
        Ops.set(fcp_map, "br_lba", "0")
        Ops.set(configuration, "fcp", fcp_map)
        Builtins.y2milestone("ModifyReiplWithBootPartition: modified fcp map")
      else
        Builtins.y2error("ModifyReiplWithBootPartition: Unknown disk type!")
        Ops.set(configuration, "method", "unknown_disk_type")
      end

      deep_copy(configuration)
    end

    # Read all reipl settings
    # @return [Hash{String => Object}] of settings
    def ReadState
      configuration = {}
      Ops.set(
        configuration,
        "ccw",
        { "device" => "", "loadparm" => "", "parm" => "" }
      )
      Ops.set(
        configuration,
        "fcp",
        {
          "device"   => "",
          "wwpn"     => "",
          "lun"      => "",
          "bootprog" => "",
          "br_lba"   => ""
        }
      )

      if !SanityCheck()
        Builtins.y2error("Reipl::Read: SanityCheck failed!")

        # Popup::Error (_("This machine does not support reipl!"));
        # Don't bother the user, just silently do shutdown in the end.
        #    Especially, since this would currently popup three times
        #    during installation.

        return deep_copy(configuration)
      end

      if @ccw_exists
        ccw_map = Ops.get_map(configuration, "ccw")

        Ops.set(
          ccw_map,
          "device",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(
                path(".target.string"),
                Ops.add(@ccw_directory, "/device")
              )
            ),
            "\n "
          )
        )
        Ops.set(
          ccw_map,
          "loadparm",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(
                path(".target.string"),
                Ops.add(@ccw_directory, "/loadparm")
              )
            ),
            "\n "
          )
        )
        Ops.set(
          ccw_map,
          "parm",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(path(".target.string"), Ops.add(@ccw_directory, "/parm"))
            ),
            "\n "
          )
        ) # SLES 11 and z/VM only

        Ops.set(configuration, "ccw", ccw_map)
      else
        Builtins.y2warning("Reipl::Read: ccw is not configured.")
      end

      if @fcp_exists
        fcp_map = Ops.get_map(configuration, "fcp")

        Ops.set(
          fcp_map,
          "device",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(
                path(".target.string"),
                Ops.add(@fcp_directory, "/device")
              )
            ),
            "\n "
          )
        )
        Ops.set(
          fcp_map,
          "wwpn",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(path(".target.string"), Ops.add(@fcp_directory, "/wwpn"))
            ),
            "\n "
          )
        )
        Ops.set(
          fcp_map,
          "lun",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(path(".target.string"), Ops.add(@fcp_directory, "/lun"))
            ),
            "\n "
          )
        )
        Ops.set(
          fcp_map,
          "bootprog",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(
                path(".target.string"),
                Ops.add(@fcp_directory, "/bootprog")
              )
            ),
            "\n "
          )
        )
        Ops.set(
          fcp_map,
          "br_lba",
          Builtins.deletechars(
            Convert.to_string(
              SCR.Read(
                path(".target.string"),
                Ops.add(@fcp_directory, "/br_lba")
              )
            ),
            "\n "
          )
        )

        Ops.set(configuration, "fcp", fcp_map)
      else
        Builtins.y2warning("Reipl::Read: fcp is not configured.")
      end

      Ops.set(
        configuration,
        "method",
        Builtins.deletechars(
          Convert.to_string(
            SCR.Read(
              path(".target.string"),
              Ops.add(@reipl_directory, "/reipl_type")
            )
          ),
          "\n "
        )
      )

      deep_copy(configuration)
    end

    # Read all reipl settings
    # @return true on success
    def Read
      configuration = ReadState()

      @reipl_configuration = deep_copy(configuration) if configuration != nil

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

      if Ops.get(configuration, "method") != nil &&
          Ops.get_string(configuration, "method", "unknown_disk_type") !=
            "unknown_disk_type"
        Builtins.y2milestone(
          "Reipl::WriteState: writing out method %1",
          Ops.get_string(configuration, "method", "")
        )

        SCR.Write(
          path(".target.string"),
          Ops.add(@reipl_directory, "/reipl_type"),
          Ops.get_string(configuration, "method")
        ) 
        #   I see a difference between the value written to the log and written to sysfs:
        #   configuration["method"]:"" <===> (string)configuration["method"]:nil
        #   But that's probably OK here and not the reason for the obvious bug in the y2log.
      end

      if @ccw_exists
        result = nil
        echoCmd = nil

        Builtins.y2milestone(
          "Reipl::WriteState: writing out ccw configuration."
        )

        ccw_map = Ops.get_map(configuration, "ccw")

        if ccw_map != nil
          Builtins.y2milestone(
            "Reipl::WriteState: ccw_map device is now \"%1\"",
            Ops.get_string(ccw_map, "device", "???")
          )
          Builtins.y2milestone(
            "Reipl::WriteState: ccw_map loadparm is now \"%1\"",
            Ops.get_string(ccw_map, "loadparm", "???")
          )

          # NOTE: It should be this, but you cannot write an empty ("") string out!
          #	    rc = SCR::Write (.target.string, ccw_directory + "/device", (string)ccw_map["device"]:nil);
          #	    rc = SCR::Write (.target.string, ccw_directory + "/loadparm", (string)ccw_map["loadparm"]:nil);

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(ccw_map, "device")),
                "\" > "
              ),
              @ccw_directory
            ),
            "/device"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing ccw device returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(ccw_map, "loadparm")),
                "\" > "
              ),
              @ccw_directory
            ),
            "/loadparm"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing ccw loadparm returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end
        else
          Builtins.y2error("Reipl::WriteState: ccw_map is nil!")

          rc = false
        end
      end

      if @fcp_exists
        result = nil
        echoCmd = nil

        Builtins.y2milestone(
          "Reipl::WriteState: writing out fcp configuration."
        )

        fcp_map = Ops.get_map(configuration, "fcp")

        if fcp_map != nil
          Builtins.y2milestone(
            "Reipl::WriteState: fcp_map device is now \"%1\"",
            Ops.get_string(fcp_map, "device", "???")
          )
          Builtins.y2milestone(
            "Reipl::WriteState: fcp_map wwpn is now \"%1\"",
            Ops.get_string(fcp_map, "wwpn", "???")
          )
          Builtins.y2milestone(
            "Reipl::WriteState: fcp_map lun is now \"%1\"",
            Ops.get_string(fcp_map, "lun", "???")
          )
          Builtins.y2milestone(
            "Reipl::WriteState: fcp_map bootprog is now \"%1\"",
            Ops.get_string(fcp_map, "bootprog", "???")
          )
          Builtins.y2milestone(
            "Reipl::WriteState: fcp_map br_lba is now \"%1\"",
            Ops.get_string(fcp_map, "br_lba", "???")
          )

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(fcp_map, "device")),
                "\" > "
              ),
              @fcp_directory
            ),
            "/device"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing fcp device returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(fcp_map, "wwpn")),
                "\" > "
              ),
              @fcp_directory
            ),
            "/wwpn"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing fcp wwpn returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(fcp_map, "lun")),
                "\" > "
              ),
              @fcp_directory
            ),
            "/lun"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing fcp lun returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(fcp_map, "bootprog")),
                "\" > "
              ),
              @fcp_directory
            ),
            "/bootprog"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing fcp bootprog returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end

          echoCmd = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add("echo \"", Ops.get_string(fcp_map, "br_lba")),
                "\" > "
              ),
              @fcp_directory
            ),
            "/br_lba"
          )
          Builtins.y2milestone("Executing %1", echoCmd)
          result = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), echoCmd)
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Builtins.y2error(
              "Error: Writing fcp br_lba returns %1",
              Ops.get_string(result, "stderr", "")
            )

            rc = false
          end
        else
          Builtins.y2error("Reipl::Write: fcp_map is nil!")

          rc = false
        end
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
    publish :function => :FindSysfsRoot, :type => "string ()"
    publish :variable => :reipl_configuration, :type => "map <string, any>"
    publish :variable => :reipl_directory, :type => "string"
    publish :variable => :ccw_directory, :type => "string"
    publish :variable => :fcp_directory, :type => "string"
    publish :variable => :ccw_exists, :type => "boolean"
    publish :variable => :fcp_exists, :type => "boolean"
    publish :function => :SanityCheck, :type => "boolean ()"
    publish :function => :FindBootPartition, :type => "list <string> ()"
    publish :function => :ModifyReiplWithBootPartition, :type => "map <string, any> (map <string, any>)"
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
