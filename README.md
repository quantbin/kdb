# kdb-flex-integration
## c.as
c.as is an ActionScript library that allows Adobe Flex applications to interact with kdb+ (like c.java or c.cs do). The idea behind this project is to be able to leverage UI capabilities of Flex in order to visualize historical and real time kdb+ data.

Calling q from ActionScript is very simple:
```
    var q:c=new c(host, port, user);
    q.ksync("select time, totvol, price from trade ...", this, "trades");
```
When response from kdb+ arrives, "trades" setter is called (note that Flex is an event-driven asynchronous environment):
```
    public function set trades(dict:Object):void {...}
```
Asynchronous call (response ignored):
```
q.kasync("x:1");
```
Below are two sample applications that use as-q library. I am also attaching binaries for each application. Binaries are not signed, so you may receive an "unknown publisher" certificate warning. You may also get a prompt to install Adobe AIR runtime, which you need to run these applications.

I will be releasing the source code for both application and the library soon.

If you find this project interesting, feel free to drop me a line at aboudarov@gmail.com (Alex Boudarov). Any feedback is welcome.
## QUI
QUI is a q learning tool that uses as-q library. It is a basic q shell combined with q idioms' code. Log at the bottom shows IPC messages. Code edit view is separate from results view, CTRL+SHIFT execute current line or selection from code view.

![alt tag](http://as-q.weebly.com/uploads/8/1/4/1/8141560/6675681_orig.png)



## TAQ
Trade and quote application is another use case for as-q library. It allows user to drill down into taq database (hope it works with your table schema). I was amazed by responsiveness of this app, which shouldn't come as a surprise considering that there is nothing between Flex and kdb+ except TCP pipe sending raw data. No message queues, no application servers, no frameworks - just data:)

![alt tag](http://as-q.weebly.com/uploads/8/1/4/1/8141560/7849429_orig.png)
