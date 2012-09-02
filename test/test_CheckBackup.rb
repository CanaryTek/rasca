require "helper"
require "fileutils"

class TestCheckBackup < Test::Unit::TestCase

  context "A CheckBackup on a volume without backups" do
    setup do
      FileUtils.rm Dir.glob('test/CheckBackup/lastbackups/*');
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/nobackups"
      @check.testing=File.read("test/CheckBackup/output.txt")
    end

    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if volume not skip' do
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
      @check.testing=File.read("test/CheckBackup/output.txt")
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
      @check.testing=File.read("test/CheckBackup/output.txt")
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
      @check.testing=File.read("test/CheckBackup/output.txt")
    end

    should 'set status OK' do
      @check.check
      assert_equal "OK",@check.status, "Status is right"
    end
  end
end
