
import config from './config.js';
import {Telegraf} from 'telegraf';

import dbus from 'dbus-next';

dbus.setBigIntCompat( true );


class Chat {
	constructor( sendFn ) {
		this.fns = [];
		this.sendFn = sendFn;
	}
	
	_received( sender, message ) {
		this.fns.forEach( fn=>fn(sender, message) );
	}
	
	send( sender, message ) {
		this.sendFn( sender, message );
	}

	onMessage( fn ) {
		this.fns.push( fn );
	}
}


async function signalInit() {
	const bus = dbus.sessionBus();
	
	const obj = await bus.getProxyObject( 'org.asamk.Signal', '/org/asamk/Signal' );
	const iface = obj.getInterface( "org.asamk.Signal" );
	// console.log( iface.$methods );
	// console.log( iface.$signals );
	
	
	const chat = new Chat( (sender, message)=>{
		iface.sendGroupMessage( `${sender}: ${message}`, [], targetGroup );
	});
	

	const targetGroup = Buffer.from( config.signal.group, 'base64');
	
	iface.on( 'SyncMessageReceived', async(timestamp, sender, destination, groupID, message, attachments)=>{
		const senderName = await iface.getContactName( sender );
		console.log( `[sync message] ${senderName} (${sender}): "${message}" in group ${groupID.toString("base64")}` );
		if( targetGroup.compare(groupID) || !message ) { return; }

		// iface.sendMessage( message, [], [sender] );
		// iface.sendGroupMessage( `${senderName} (${sender}) just wrote: "${message}" here`, [], targetGroup );
		chat._received( senderName, message );
	});
	iface.on( 'MessageReceived', async(timestamp, sender, groupID, message, attachments)=>{
		const senderName = await iface.getContactName( sender );

		console.log( `[message] ${senderName} (${sender}): "${message}" in group ${groupID.toString("base64")}` );
		if( targetGroup.compare(groupID) || !message ) { return; }

		// iface.sendMessage( message, [], [sender] );
		// iface.sendGroupMessage( `${senderName} (${sender}) just wrote: "${message}" here`, [], targetGroup );
		chat._received( senderName, message );
	});
	
	console.log( `Signal ready!` );
	// bus.disconnect();

	return chat;
}

async function telegramInit() {
	const bot = new Telegraf( config.telegram.token );
	
	const chat = new Chat( (sender, message)=>{
		message = message.replace( /&/g, '&amp;' ).replace( /</g, '&lt;' ).replace( />/g, '&gt;' );
		bot.telegram.sendMessage( config.telegram.group, `<b>${sender}</b>: ${message}`, {parse_mode:"HTML"} );
	});
	
	bot.on( 'text', ctx=>{
		if( ! ctx.message.from ) { return; }
		
		const {from} = ctx.message;
		const namePieces = [from.first_name, from.last_name, from.username ? `@${from.username}` : ``];
		const name = namePieces.filter( x=>!!x ).join( ` ` );

		console.log( `${name}: "${ctx.message.text}" in ${ctx.message.chat.id} (${ctx.message.chat.title})` );
		if( `${ctx.message.chat.id}` !== config.telegram.group ) { return; }
		
		chat._received( name, ctx.message.text );
	});
	
	bot.launch();
	
	console.log( `Telegram ready!` );
	
	return chat;
}

async function main() {
	const telegram = await telegramInit();
	const signal = await signalInit();

	telegram.onMessage( (sender, message)=>signal.send(sender, message) );
	signal.onMessage( (sender, message)=>telegram.send(sender, message) );
}

main().catch( (err)=>{
	console.error( err );
});

