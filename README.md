## emanator

This is a library for building and incrementally updating materialized views.
It converts logically replicated change data from a local or remote postgres
database into SQL statements that update the view table.

emanator is different from plain old views because view data is materialized.
The replica view table is durable and can be directly queried.

emanator is different from postgres' materialized views because it incrementally
rebuilds the view with each change. Instead of periodically rebuilding the view
by executing the original query, the emanator replica view is always updating.

emanator is eventually consistent. The view replica may lag the master until new
changes are processed. It is strongly consistent after failures; it uses txids
to replay changes that have not already committed.
