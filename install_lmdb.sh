SOURCE_DIR=`pwd`
LMDB_DIR_URL="https://github.com/caketechio/lmdb.git"
LMDB_DIR_PATH="$SOURCE_DIR/lmdb/Sources"

echo "============================ LMDB ============================"
mkdir -p $LMDB_DIR_PATH
echo "Cloning lmdb from - $LMDB_DIR_URL"
git clone -b build $LMDB_DIR_URL $LMDB_DIR_PATH
cd $SOURCE_DIR