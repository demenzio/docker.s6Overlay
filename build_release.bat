@echo off

title Build Script v1.0.0

set ver=
set dist=amd64
set choice=n

:CHOICEno

cls 

echo  Building xuvin/s6overlay:release

echo   Version: %ver%
echo   Arch   : %dist%
echo.

set /p ver="Choose Version (vX.XX.X.X) [%ver%]: "

IF not defined ver (
  cls
  GOTO ERROR1
) ELSE (GOTO QUESTION)

REM GOTO - Section

:EXIT
cmd /k

:ERROR1
echo  Error 1 - No Version Entered
echo.
set /p ver="Choose Version (vX.XX.X.X) [%ver%]: "

IF not defined ver (
  cls
  GOTO ERROR1
) ELSE (GOTO QUESTION)

:QUESTION
cls
:CHOICEnotvalid
echo.
echo  Building xuvin/s6overlay:alpine-%ver%
echo  and
echo  Building xuvin/s6overlay:ubuntu-%ver%
echo.
set /p choice="Are you sure? [y/n]: "

IF %choice%==y (
  set choice=n
  GOTO BUILD
) ELSE (
  IF %choice%==n (
    GOTO CHOICEno
  ) ELSE (
    cls
    echo.
    echo  No valid answer given.
    echo.
    GOTO CHOICEnotvalid
  )
) 

:BUILD
cls
echo.
echo  Building xuvin/s6overlay:alpine-%ver%
echo.
docker build -f Dockerfile.alpine --build-arg VERSION=%ver% -t xuvin/s6overlay:alpine-%ver%  .
cls
echo.
echo  Building xuvin/s6overlay:ubuntu-%ver%
echo.
docker build -f Dockerfile.ubuntu --build-arg VERSION=%ver% -t xuvin/s6overlay:ubuntu-%ver% .
cls
echo.
echo  DONE.
echo  Have a nice day. :)
echo.
GOTO EXIT