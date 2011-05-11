create keyspace ruote_work
    with replication_factor = 2
    and placement_strategy = 'org.apache.cassandra.locator.SimpleStrategy';

use ruote_work;

create column family configurations with comparator = UTF8Type;
create column family errors with comparator = UTF8Type;
create column family msgs with comparator = UTF8Type;
create column family expressions with comparator = UTF8Type;
create column family variables with comparator = UTF8Type;
create column family schedules with comparator = UTF8Type;