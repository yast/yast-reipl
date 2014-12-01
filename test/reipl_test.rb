#!/usr/bin/env rspec

ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)

require "yast"
Yast.import "Reipl"

describe "Reipl#ReadState" do
  it "returns map of lsreipl call" do
    lsreipl_output = "Re-IPL type: ccw
      Device:      0.0.7e64
      Loadparm:    \"\""

    lsreipl_map = {
      "ccw" => {"device"=>"0.0.7e64", "loadparm"=>"", "parm"=>""},
      "fcp" => {"device"=>"", "wwpn"=>"", "lun"=>"", 
                "bootprog"=>"", "br_lba"=>"", "bootparms"=>""},
      "method" => "ccw",
      "nss" => {"name"=>"", "loadparm"=>"", "parm"=>""}
    }

    expect(Yast::SCR).to receive(:Execute).with(anything(), /lsreipl/).and_return({ "exit" => 0, "stderr" => "", "stdout" => lsreipl_output })

    expect(Yast::Reipl.ReadState()).to eq( lsreipl_map )
  end

end
