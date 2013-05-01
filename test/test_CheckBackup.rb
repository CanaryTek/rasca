require "helper"
require "fileutils"

class TestCheckBackup < Test::Unit::TestCase

  context "CheckBackup's translate_to_mapper" do
    setup do
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
    end
    should "convert /dev/sys/var to /dev/mapper/sys_var" do
      assert_equal "/dev/mapper/sys-var",@check.convert_to_mapper("/dev/sys/var")
    end
    should "convert /dev/sys/dom0_root to /dev/mapper/sys-dom0_root" do
      assert_equal "/dev/mapper/sys-dom0_root",@check.convert_to_mapper("/dev/sys/dom0_root")
    end
  end

  context "CheckBackup's translate_from_mapper" do
    setup do
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
    end
    should "convert /dev/mapper/sys-var to /dev/sys/var" do
      assert_equal "/dev/sys/var",@check.convert_from_mapper("/dev/mapper/sys-var")
    end
    should "convert /dev/mapper/sys-dom0_root to /dev/sys/dom0_root" do
      assert_equal "/dev/sys/dom0_root",@check.convert_from_mapper("/dev/mapper/sys-dom0_root")
    end
  end


  # Check LVM volumes
  context "A CheckBackup on a volume without backups" do
    setup do
      FileUtils.rm Dir.glob('test/CheckBackup/lastbackups/*');
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/nobackups"
      @check.testing1=File.read("test/CheckBackup/output_lvscan.txt")
      @check.testing2=""
    end

    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if volume not skip' do
      @check.readObjects("CheckBackup")
      @check.check
      assert_equal "WARNING",@check.status
    end
    should 'set status OK when volume is skipped' do
      @check.object_dir="test/CheckBackup/skipped"
      @check.check
      assert_equal "OK",@check.status
    end
    should 'set status OK when we skip all volumes, and show configured messages' do
      @check=Rasca::CheckBackup.new("CheckBackup","test/CheckBackup/etc_skip_backups",true,true)
      @check.object_dir="test/CheckBackup/nobackups"
      @check.check
      assert_equal "OK",@check.status, "Status OK"
      assert_equal "Backups on dom0",@check.short, "Shows right massage"
    end
  end

  context "A CheckBackup on a volume with OLD backups" do
    setup do
      ["dom0_root","dom0_var","dom0_opt"].each do |file|
        FileUtils.touch("test/CheckBackup/lastbackups/#{file}",:mtime=>Time.now-60*60*48)
      end
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/old_backups"
      @check.testing1=File.read("test/CheckBackup/output_lvscan.txt")
      @check.testing2=""
    end

    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if backup is too old' do
      @check.check
      assert_equal "WARNING",@check.status, "Status is right"
      assert_match "OLD",@check.short,"Message reports OLD backup"
    end
  end

  context "A CheckBackup on a volume with CURRENT backups" do
    setup do
      ["dom0_root","dom0_var","dom0_opt"].each do |file|
        FileUtils.touch("test/CheckBackup/lastbackups/#{file}")
      end
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/old_backups"
      @check.testing1=File.read("test/CheckBackup/output_lvscan.txt")
      @check.testing2=""
    end

    should 'set status OK' do
      @check.check
      assert_equal "OK",@check.status, "Status is right"
    end
  end

  ## Check filesystems
  context "A CheckBackup on a filesystem without backups" do
    setup do
      FileUtils.rm Dir.glob('test/CheckBackup/lastbackups/*');
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/nobackups"
      @check.testing1=""
      @check.testing2=File.read("test/CheckBackup/output_df.txt")
    end
    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if filesystem not skip' do
      @check.readObjects("CheckBackup")
      @check.check
      assert_equal "WARNING",@check.status
    end
    should 'set status OK when filesystem is skipped' do
      @check.object_dir="test/CheckBackup/skipped"
      @check.check
      assert_equal "OK",@check.status
    end
    should 'set status OK when we skip all filesystem, and show configured messages' do
      @check=Rasca::CheckBackup.new("CheckBackup","test/CheckBackup/etc_skip_backups",true,true)
      @check.object_dir="test/CheckBackup/nobackups"
      @check.check
      assert_equal "OK",@check.status, "Status OK"
      assert_equal "Backups on dom0",@check.short, "Shows right massage"
    end
  end
  context "A CheckBackup on a filesystem with OLD backups" do
    setup do
      ["_","_var","_boot","_home"].each do |file|
        FileUtils.touch("test/CheckBackup/lastbackups/#{file}",:mtime=>Time.now-60*60*48)
      end
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/old_backups"
      @check.testing1=""
      @check.testing2=File.read("test/CheckBackup/output_df.txt")
    end

    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if backup is too old' do
      @check.check
      assert_equal "WARNING",@check.status, "Status is right"
      assert_match "OLD",@check.short,"Message reports OLD backup"
    end
  end

  context "A CheckBackup on a filesystem with CURRENT backups" do
    setup do
      ["root","_var","_boot","_home"].each do |file|
        FileUtils.touch("test/CheckBackup/lastbackups/#{file}")
      end
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/old_backups"
      @check.testing1=""
      @check.testing2=File.read("test/CheckBackup/output_df.txt")
    end

    should 'set status OK' do
      @check.check
      assert_equal "OK",@check.status, "Status is right"
    end
  end

  context "A CheckBackup with current backups" do
    setup do
      ["root","_var","_boot","_home"].each do |file|
        FileUtils.touch("test/CheckBackup/lastbackups/#{file}")
      end
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/old_backups"
      @check.testing1=File.read("test/CheckBackup/output_lvscan2.txt")
      @check.testing2=File.read("test/CheckBackup/output_df2.txt")
    end

    should 'identify /dev/sys/dom0_myvar as the same as /var' do
      @check.check
      assert_equal "OK",@check.status, "Status is right"
    end
  end
end
