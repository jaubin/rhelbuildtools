# rhelbuildtools

rhelbuildtools contains various scripts used in order to automatically build RPM packages and so on. 

These tools are designed to be used with continuous integration systems like Jenkins. They're to be used with Git. Note that we do not use mock in most of these tools, meaning that they should NOT be used in order to build C code. This is because of performance reasons as mock is extremely expensive to run on a CI server
