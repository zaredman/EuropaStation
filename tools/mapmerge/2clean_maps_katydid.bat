cd ../../maps/katydid

FOR /R %%f IN (*.dmm) DO (
  java -jar ../../tools/mapmerge/MapPatcher.jar -clean %%f.backup %%f %%f
)

pause