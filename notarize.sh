#chmod +x ./BackOffice.app/Contents/MacOS/BackOffice               
#xattr -r -d com.apple.quarantine ./Bin/Debug/macOS/WUnite.Backoffice.app
#xattr -r -d com.apple.FinderInfo ./Bin/Debug/macOS/WUnite.Backoffice.app
codesign -v --deep --force -o runtime --sign "Developer ID Application: RemObjects Software" ./Bin/DeveloperID/macOS/Verbs.app
rm "./Bin/DeveloperID/Verbs.dmg"
hdiutil create -fs HFS+ -volname "Verbs" -size 10G -srcfolder "./Bin/DeveloperID/macOS" "./Bin/DeveloperID/Verbs.dmg"
xcrun notarytool submit "./Bin/DeveloperID/Verbs.dmg" --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple "./Bin/DeveloperID/Verbs.dmg"
