#!/bin/bash
COUNT=$(dunstctl count waiting)
if [ "$COUNT" -gt 0 ]; then
  echo "true"
else
  echo "false"
fi
