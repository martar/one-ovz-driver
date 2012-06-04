require 'open_vz_driver'
require 'openvz'
require 'test_utils'
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTestModule < Test::Unit::TestCase
    ONE_VMID = 49
    DISK = File.absolute_path 'test/resources/disk.0'
    ISO_IMG = File.absolute_path 'test/resources/disk.2'
    def setup
      @inventory = OpenVZ::Inventory.new
      @driver = OpenVzDriver.new
    end
    
    def test_deploy
      # init
      @open_vz_data = OpenVzData.new(File.new "test/resources/deployment_file_no_context_test.xml")
      ctid = OpenVzDriver.ctid @inventory
      container = OpenVZ::Container.new(ctid)
      # mock container's disk path
      @open_vz_data = flexmock(@open_vz_data)
      @open_vz_data.should_receive(:disk).times(1).and_return(DISK)

      OpenVzDriverTestModule.mock_tmm
      
      # deploy
      deploy_ctid = @driver.deploy @open_vz_data, container
      
      # assert
      assert @open_vz_data.context == nil
      assert_equal ctid, deploy_ctid
      # this assertion works if the test is executed as a root user
      assert_equal true, File.directory?("/vz/private/#{deploy_ctid}")
    ensure
      OpenVzDriverTestModule.cleanup deploy_ctid
    end

    def test_deploy_with_ctx
      # init
      @open_vz_data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")
      ctid = OpenVzDriver.ctid @inventory
      container = OpenVZ::Container.new(ctid)
      # mock container's disk path
      @open_vz_data = flexmock(@open_vz_data)
      @open_vz_data.should_receive(:disk).times(1).and_return(DISK)

      OpenVzDriverTestModule.mock_tmm

      # deploy
      deploy_ctid = @driver.deploy @open_vz_data, container

      # ctx assertions
      assert @open_vz_data.context != nil
      assert "tst\n" == container.command('cat /tmp/tst')

      # deployment assertions
      assert_equal ctid, deploy_ctid
      # this assertion works if the test is executed as a root user
      assert_equal true, File.directory?("/vz/private/#{deploy_ctid}")
    ensure
      OpenVzDriverTestModule.cleanup deploy_ctid
    end

    def self.cleanup(deploy_ctid)
      if deploy_ctid
        TestUtils.purge_ct deploy_ctid
        TestUtils.purge_template "/vz/template/cache/one-#{deploy_ctid}.tar.gz"
        File.unlink "/vz/one/datastores/0/#{ONE_VMID}/disk.2.iso"
        Dir.rmdir "/vz/one/datastores/0/#{ONE_VMID}"
      end
    end

    def self.mock_tmm()
      # these 2 lines mock TMM
      Dir.mkdir "/vz/one/datastores/0/#{ONE_VMID}" unless File.exists? "/vz/one/datastores/0/#{ONE_VMID}"
      File.symlink "#{ISO_IMG}", "/vz/one/datastores/0/#{ONE_VMID}/disk.2.iso"
    end
  end
end
