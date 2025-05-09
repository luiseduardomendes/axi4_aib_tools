# read_flist.tcl - Dead-simple file list reader
proc read_flist {f_file} {
    set files []
    set fp [open $f_file r]
    while {[gets $fp line] >= 0} {
        set line [string trim $line]
        # Skip empty lines and comments
        if {$line eq "" || [string match "#*" $line]} continue
        # Just expand what we can with subst
        lappend files [subst $line]
    }
    close $fp
    return $files
}

# Example usage:
# set PROJ_DIR "/your/project/path"
# set files [read_flist "your_filelist.f"]
# add_files $files