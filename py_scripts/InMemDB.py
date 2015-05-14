#!/usr/bin/python

from os import sys


# The in-memory database class
class MemDB:

    # Inner class for supported ops and their attributes
    class Op:
        def __init__(self, num_args, func):
            self.num_args = num_args
            self.func = func

    # Initialize the database along with supported ops
    def __init__(self):
        self._db = {}
        self._transactions = []
        self._ops = {
            'SET':  MemDB.Op(2, self.set),
            'UNSET': MemDB.Op(1, self.unset),
            'GET': MemDB.Op(1, self.get),
            'COMMIT': MemDB.Op(0, self.commit),
            'ROLLBACK': MemDB.Op(0, self.rollback),
            'BEGIN': MemDB.Op(0, self.begin),
            'NUMEQUALTO': MemDB.Op(1, self.numequalto)
        }

    # Write value or delete from DB
    def _write(self, name, value):
        if (value is not None):
            self._db[name] = value
        else:
            del self._db[name]

    # Begin a transaction by pushing one onto our stack
    def begin(self):
        self._transactions.append({})

    # Set a variable and track changes if a transaction is open
    # running time = O(1)
    def set(self, name, value):
        if (len(self._transactions) > 0):
            if name in self._db:
                self._transactions[-1][name] = self._db[name]
            else:
                self._transactions[-1][name] = None

        self._write(name, value)

    # Unset a variable
    # running time = O(1)
    def unset(self, name):
        if name in self._db:
            self.set(name, None)

    # Get value, or NULL if missing
    # running time = O(1)
    def get(self, name):
        print self._db[name] if name in self._db else "NULL"

    # Rollback current transaction from top-of-stack and pop it off
    def rollback(self):
        if len(self._transactions) > 0:
            for name, old_value in self._transactions[-1].items():
                self._write(name, old_value)

            self._transactions.pop()

    # Commit transaction by popping off top-of-stack transaction
    def commit(self):
        if len(self._transactions) > 0:
            self._transactions.pop()

    # Find all values matching given value.
    # Running time = O(n). Can make it O(1) with a reverse lookup dictionary
    # but that depends on how important this operation's efficiency is.
    def numequalto(self, num):
        print len([x for x in self._db.values() if x == num])

    # Main method to sanitize input and run queries
    def run_query(self, query):
        args = query.split(' ')
        cmd = args.pop(0).upper()

        # Check for illegal commands
        if cmd not in self._ops:
            print "Illegal command '%s'. Try again!" % cmd
            return

        # Check if number of arguments to command is correct
        if len(args) != self._ops[cmd].num_args:
            print "Command %s expects %d arguments. Try again!" % \
                (cmd, self._ops[cmd].num_args)
            return

        # Run query
        self._ops[cmd].func(*args)


def main():
    db = MemDB()
    input = sys.stdin.readline().strip()

    # Keep running queries until end keyword is observed
    while input.upper() != 'END':
        db.run_query(input)
        input = sys.stdin.readline().strip()

if __name__ == "__main__":
    main()
