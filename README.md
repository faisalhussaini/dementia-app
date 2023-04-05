# dementia-app

This project requires Alamofire to work. To make sure this runs without any issues, please do the following:

1) brew install cocoapods
2) go the directory containing the Podfile, and run: "pod install"
-> This allows Alamofire to work.
3) Build Xcode project as usual


Note:
If you get into the project and it says some bs about a missing xc environment, do:
1) goto General Project settings
2) scroll down to Frameworks, Libraries, and Embedded Content
3) Finally make sure the one package that is there has Embed label: Embed & Sign
-> If not, change it to Embed and Sign, then rebuild and all will be well
