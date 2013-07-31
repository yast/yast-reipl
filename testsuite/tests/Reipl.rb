# encoding: utf-8

module Yast
  class ReiplClient < Client
    def main
      # testedfiles: Reipl.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "Reipl"

      DUMP("Reipl::Modified")
      TEST(lambda { Reipl.Modified }, [], nil)

      nil
    end
  end
end

Yast::ReiplClient.new.main
