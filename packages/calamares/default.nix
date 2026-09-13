{
  calamares,
  extraWrapperArgs ? [ ],
}:
(calamares.overrideAttrs (prev: {
  patches = (prev.patches or [ ]) ++ [
    ./0001-welcome-Add-efi-check.patch
    ./0002-argonid-sectorsize.patch
  ];
})).override
  { inherit extraWrapperArgs; }
