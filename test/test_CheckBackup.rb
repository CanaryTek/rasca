require "helper"
require "fileutils"

class TestCheckBackup < Test::Unit::TestCase

  context "CheckBackup's fs_types_to_backup" do
    setup do
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.fs_types_cmd="/usr/bin/grep -v nodev test/CheckBackup/proc_filesystems.txt"
    end
    should "return correct filesystems array" do
      assert_equal ["ext3","ext2","ext4"],@check.fs_types_to_backup
    end
  end

  context "CheckBackup's get_mounts_to_backup" do
    setup do
     @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
    end
    should "return correct hash for test/CheckBackup/output_mount.txt" do
       @result={
        "/dev/mapper/sys-dom0_root" => { 
          :dev => "/dev/mapper/sys-dom0_root",
          :mount => "/",
          :fstype => "ext3"
        },
        "/dev/mapper/sys-dom0_var" => { 
          :dev => "/dev/mapper/sys-dom0_var",
          :mount => "/var",
          :fstype => "ext3"
        },
        "/dev/sda1" => { 
          :dev => "/dev/sda1",
          :mount => "/boot",
          :fstype => "ext3"
        }
      }
      @check.mount_cmd="/usr/bin/cat test/CheckBackup/output_mount.txt"
      assert_equal @result,@check.get_mounts_to_backup
    end
    should "return correct hash for test/CheckBackup/output_mount2.txt" do
       @result={
        "/dev/mapper/fedora-root" => { 
          :dev => "/dev/mapper/fedora-root",
          :mount => "/",
          :fstype => "ext4"
        },
        "/dev/sda1" => { 
          :dev => "/dev/sda1",
          :mount => "/boot",
          :fstype => "ext4"
        },
        "/dev/mapper/fedora-home" => { 
          :dev => "/dev/mapper/fedora-home",
          :mount => "/home",
          :fstype => "ext4"
        },
        "/dev/mapper/fedora-var" => { 
          :dev => "/dev/mapper/fedora-var",
          :mount => "/var",
          :fstype => "ext4"
        },
      }
      @check.mount_cmd="/usr/bin/cat test/CheckBackup/output_mount2.txt"
      assert_equal @result,@check.get_mounts_to_backup
    end
  end

  context "CheckBackup's get_lvs_to_backup" do
    setup do
     @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
    end
    should "NOT add any LV to test/CheckBackup/output_lvscan.txt" do
       @result={
        "/dev/mapper/sys-dom0_root" => { 
          :dev => "/dev/mapper/sys-dom0_root",
          :mount => "/",
          :fstype => "ext3"
        },
        "/dev/mapper/sys-dom0_var" => { 
          :dev => "/dev/mapper/sys-dom0_var",
          :mount => "/var",
          :fstype => "ext3"
        },
        "/dev/sda1" => { 
          :dev => "/dev/sda1",
          :mount => "/boot",
          :fstype => "ext3"
        }
      }
      @check.lvscan_cmd="/usr/bin/cat test/CheckBackup/output_lvscan.txt"
      assert_equal @result,@check.get_lvs_to_backup(@result)
    end
    should "add 2 LV to test/CheckBackup/output_lvscan2.txt" do
       @in={
        "/dev/mapper/fedora-root" => { 
          :dev => "/dev/mapper/fedora-root",
          :mount => "/",
          :fstype => "ext4"
        },
        "/dev/sda1" => { 
          :dev => "/dev/sda1",
          :mount => "/boot",
          :fstype => "ext4"
        },
        "/dev/mapper/fedora-home" => { 
          :dev => "/dev/mapper/fedora-home",
          :mount => "/home",
          :fstype => "ext4"
        },
        "/dev/mapper/fedora-var" => { 
          :dev => "/dev/mapper/fedora-var",
          :mount => "/var",
          :fstype => "ext4"
        },
      }
      @result={
        "/dev/mapper/fedora-root" => { 
          :dev => "/dev/mapper/fedora-root",
          :mount => "/",
          :fstype => "ext4"
        },
        "/dev/sda1" => { 
          :dev => "/dev/sda1",
          :mount => "/boot",
          :fstype => "ext4"
        },
        "/dev/mapper/fedora-home" => { 
          :dev => "/dev/mapper/fedora-home",
          :mount => "/home",
          :fstype => "ext4"
        },
        "/dev/mapper/fedora-var" => { 
          :dev => "/dev/mapper/fedora-var",
          :mount => "/var",
          :fstype => "ext4"
        },
        "/dev/mapper/sys-dom0_myroot" => {
          :dev => "/dev/mapper/sys-dom0_myroot",
          :lvname => "/dev/sys/dom0_myroot",
        },
        "/dev/mapper/sys-dom0_myvar" => {
          :dev => "/dev/mapper/sys-dom0_myvar",
          :lvname => "/dev/sys/dom0_myvar"
        },
      }
      @check.lvscan_cmd="/usr/bin/cat test/CheckBackup/output_lvscan2.txt"
      assert_equal @result,@check.get_lvs_to_backup(@in)
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

  context "CheckBackup's volumes_to_backup" do
    setup do
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.fs_types_cmd="/usr/bin/grep -v nodev test/CheckBackup/proc_filesystems.txt"
    end
    should "return correct filesystems array" do
      assert_equal ["ext3","ext2","ext4"],@check.fs_types_to_backup
    end
  end

  context "CheckBackup's get_object" do
    setup do
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/get_objects"
      @check.readObjects("backup")
    end
    should "find / by mount" do
      assert_equal({:name=>"root"},@check.get_object({:dev=>"/dev/mapper/root",:mount=>"/",:fstype=>"ext3"}))
    end
    should "find /dev/dat/bck by lvname" do
      assert_equal({:skip=>"skip bck"},@check.get_object({:dev=>"/dev/mapper/dat-bck",:lvname=>"/dev/dat/bck"}))
    end
    should "find /dev/dat/bck2 by mapper name" do
      assert_equal({:skip=>"skip bck2"},@check.get_object({:dev=>"/dev/mapper/dat-bck2",:lvname=>"/dev/dat/bck2"}))
    end
    should "find dom0_opt by basename(name)" do
      assert_equal({:skip=>"skip opt"},@check.get_object({:dev=>"/dev/mapper/sys-dom0_opt",:lvname=>"/dev/sys/dom0_opt"}))
    end
    should "find dom0_var by basename(mapper name)" do
      assert_equal({:skip=>"skip var"},@check.get_object({:dev=>"/dev/mapper/sys-dom0_var",:lvname=>"/dev/sys/dom0_var"}))
    end
  end

  context "CheckBackup's find_backup_tstamp" do
    setup do
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      FileUtils.rm Dir.glob('test/CheckBackup/lastbackups/*');
      @check.object_dir="test/CheckBackup/get_objects"
      @check.readObjects("backup")
    end
    should "find root tstamp file by name 'myhost_root'" do
      FileUtils.touch("test/CheckBackup/lastbackups/myhost_root")
      assert_equal "test/CheckBackup/lastbackups/myhost_root",@check.find_backup_tstamp({:dev=>"/dev/mapper/sys-root",:mount=>"/",:fstype=>"ext3",:lvname=>"/dev/sys/root"},"myhost_root")
    end
    should "find root tstamp file by mount '_'" do
      FileUtils.touch("test/CheckBackup/lastbackups/_")
      assert_equal "test/CheckBackup/lastbackups/_",@check.find_backup_tstamp({:dev=>"/dev/mapper/sys-root",:mount=>"/",:fstype=>"ext3",:lvname=>"/dev/sys/root"},nil)
    end
    should "find root tstamp file by basename dev 'root'" do
      FileUtils.touch("test/CheckBackup/lastbackups/root")
      assert_equal "test/CheckBackup/lastbackups/root",@check.find_backup_tstamp({:dev=>"/dev/mapper/sys-root",:mount=>"/",:fstype=>"ext3",:lvname=>"/dev/sys/root"},nil)
    end
    should "find root tstamp file by basename mapper dev 'sys-root'" do
      FileUtils.touch("test/CheckBackup/lastbackups/sys-root")
      assert_equal "test/CheckBackup/lastbackups/sys-root",@check.find_backup_tstamp({:dev=>"/dev/mapper/sys-root",:mount=>"/",:fstype=>"ext3",:lvname=>"/dev/sys/root"},nil)
    end
  end

  # Check LVM volumes
  context "A CheckBackup on a volume without backups" do
    setup do
      FileUtils.rm Dir.glob('test/CheckBackup/lastbackups/*');
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/nobackups"
      @check.lvscan_cmd="/bin/cat test/CheckBackup/output_lvscan.txt"
      @check.mount_cmd="/bin/cat test/CheckBackup/output_mount.txt"
    end

    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if volume not skip' do
      @check.readObjects("backup")
      @check.check
      assert_equal "WARNING",@check.status
    end
    should 'set status OK when volume is skipped' do
      @check.object_dir="test/CheckBackup/skipped"
      @check.check
      puts "OUT: #{@check.short}"
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
      FileUtils.rm Dir.glob('test/CheckBackup/lastbackups/*');
      ["dom0_root","dom0_var","dom0_opt"].each do |file|
        FileUtils.touch("test/CheckBackup/lastbackups/#{file}",:mtime=>Time.now-60*60*48)
      end
      @check=Rasca::CheckBackup.new("CheckBackup","test/etc",true,true)
      @check.object_dir="test/CheckBackup/old_backups"
      @check.lvscan_cmd="/bin/cat test/CheckBackup/output_lvscan.txt"
      @check.mount_cmd="/bin/cat test/CheckBackup/output_mount.txt"
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
      @check.lvscan_cmd="/bin/cat test/CheckBackup/output_lvscan.txt"
      @check.mount_cmd="/bin/echo -n"
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
      @check.object_dir="nonexistent"
      @check.mount_cmd="/bin/cat test/CheckBackup/output_mount.txt"
    end
    # FIXME: Should be really CRITICAL and configurable to WARNING
    should 'set status WARNING if filesystem not skip' do
      @check.readObjects("backup")
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
      @check.mount_cmd="/bin/cat test/CheckBackup/output_mount.txt"
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
      @check.mount_cmd="/bin/cat test/CheckBackup/output_mount.txt"
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
      @check.lvscan_cmd="/bin/cat test/CheckBackup/output_lvscan2.txt"
      @check.mount_cmd="/bin/cat test/CheckBackup/output_mount2.txt"
    end

    should 'identify /dev/sys/dom0_myvar as the same as /var' do
      @check.check
      assert_equal "OK",@check.status, "Status is right"
    end
  end
end
