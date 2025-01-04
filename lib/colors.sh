if [ -t 1 ]; then
    # Terminal supports colors
    NC='\033[0m'          # No Color
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
else
    # Disable colors for non-terminal outputs (like logs)
    NC=''
    RED=''
    GREEN=''
    BLUE=''
fi