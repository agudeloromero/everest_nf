$lsYmlFiles = gci *yml

foreach($f in $lsYmlFiles) {
        $container = wave --conda-file $f
        echo $container

}
