
. ./start_script.sh

add_desc "This is a global description of the script"

add_var TOTO "toto" "this is toto"
add_var NO_DEFAULT_VALUE "" "no default value"
add_var NO_DESC "no_desc" ""

echo "############# Print Usage #############"
usage
echo ""

echo "############# Start Script #############"
export_vars $@
echo ""


echo "############# Print TOTO #############"
echo $TOTO
echo ""
echo "############# Print NO_DEFAULT_VALUE #############"
echo $NO_DEFAULT_VALUE
echo ""
echo "############# Print NO_DESC #############"
echo $NO_DESC
echo ""



