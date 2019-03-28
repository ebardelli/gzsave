pr de gzsave
* Save as gzipped dataset
*! 0.1 HS, Sep 30, 2004
*! 0.2 HS, Nov 24, 2004 Improved filename parsing
*! 0.3 HS, Oct 20, 2005 Set filename correctly after dataset saved
*! 0.4 HS, May 4, 2006  Improved filename allocation + erase instead of rm
*! 0.5 HS, Sep 7, 2009 Allow filenames enclosed in quotes
*! 0.6 EB, Aug 14, 2018 Allow to specify compression speed for gzip
*! 0.7 EB, Feb 5, 2019 Add support for pigz
version 9.2
syntax [anything(name=file)] [, replace Speed(integer 1) which(string) *]
qui {

  if `"`file'"' == "" {
    local file = `""$S_FN""'
    if `"$S_FN"' == "" {
      di in red "invalid file specification"
      exit
    }
  }

  ** Default to gzip if no program name was set
  if missing("`which'") {
    local which "gzip"
  }

  _gfn, filename(`file') extension(.dta.gz)
  local file = r(fileout)

  noi _ok2save, filename(`file') `replace'

  tempfile tmpdat
  sa `tmpdat', `options'

  shell `which' -c -`speed' `tmpdat' > "`file'"

  local filelen = ""

  mata {
    fname = st_local("file")
    fh = fopen(fname, "r")
    filepos = _fseek(fh, 0, 1)
    if (filepos >= 0) fsize = ftell(fh)
    fclose(fh)
    st_local("filelen", strofreal(fsize))
  }

  ** Check if the final dataset exists
  if ("`filelen'" == "0") {
    rm "`file'"
    di in red "Do you have `which' in your path? Use the option which() to specify the compression program to use."
    error 688
    exit
  }

  global S_FN = `"`file'"'

  noi di in green "data compressed with `which' and saved in file `file'"
}

end

* Create filename to use with compressed save/use (gzsave and zipsave)
*! 0.1 HS, Oct 1, 2009
pr de _gfn, rclass
version 9.2
syntax , filename(string asis) extension(string)

* Only check for punctuation in filename, not in path
_getfilename `filename'

* Remove opening and closing quotes, if any, from filename
if strpos(`"`filename'"', char(34)) ~= 0 {
  local filename = subinstr(`filename', char(34), "", .)
}

if index(r(filename), ".") == 0 {
  local filename "`filename'`extension'"
}
return local fileout `"`filename'"'

end


* OK to save filename with compressed save? (gzsave and zipsave)
*! 0.1 HS, Oct 1, 2009
pr de _ok2save
version 9.2
syntax , filename(string asis) [replace]

  if "`replace'" == "" {
    confirm new file "`filename'"
  }
  else {
    capture confirm file "`filename'"
    if _rc == 0 {
      erase "`filename'"
    }
    else {
       confirm new file "`filename'"
       di in green `"(note: file `filename' not found)"'
    }
  }

end

