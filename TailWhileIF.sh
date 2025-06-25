#!/bin/bash
tail -f "flutterbuild.log" | while IFS= read -r line; do
    echo "Processing line: $line";
    if [[ "$line" =~ "done" ]]; then
      echo "exist done";
      ls -la ../build/ios/iphoneos/Runner.app;
      exit 0;
      pkill -P $$ tail;
    elif [[ "$line" =~ "Failed" ]]; then
      echo "exist Failed";
exit 1;
pkill -P $$ tail;
    fi;
done;
pkill -P $$ tail;
