@echo off
REM Windows version of setup.sh
mkdir .bak
xcopy /E /I /Y lib .bak\lib >nul
xcopy /E /I /Y test .bak\test >nul
copy /Y pubspec.yaml .bak\pubspec.yaml >nul
call flutter create --org com.safro --project-name safro --platforms=android,ios .
rmdir /S /Q lib
rmdir /S /Q test
xcopy /E /I /Y .bak\lib lib >nul
xcopy /E /I /Y .bak\test test >nul
copy /Y .bak\pubspec.yaml pubspec.yaml >nul
rmdir /S /Q .bak
call flutter pub get
echo Done. Follow README.md steps 2-4, then flutter run.
