mod mc_metrics;

use std::{
    collections::{HashMap, HashSet},
    env,
    fmt::Write,
    sync::Arc,
};
use chrono::{DateTime, DurationRound, Utc};

use serenity::prelude::*;
use serenity::{
    async_trait,
    client::bridge::gateway::{GatewayIntents, ShardId, ShardManager},
    framework::standard::{
        help_commands,
        macros::{command, group, help, hook},
        Args,
        CommandError,
        CommandGroup,
        CommandResult,
        DispatchError,
        HelpOptions,
        StandardFramework,
    },
    http::Http,
    model::{
        channel::{Message},
        gateway::Ready,
        id::UserId,
    },
};
use tokio::sync::Mutex;

struct ShardManagerContainer;

impl TypeMapKey for ShardManagerContainer {
    type Value = Arc<Mutex<ShardManager>>;
}

struct CommandCounter;

impl TypeMapKey for CommandCounter {
    type Value = HashMap<String, u64>;
}

struct Handler;

#[async_trait]
impl EventHandler for Handler {
    async fn ready(&self, ctx: Context, ready: Ready) {
        println!("{} is connected!", ready.user.name);
        let status_channel_id = match env::var("STATUS_CHANNEL_ID")
            .unwrap_or("x".to_string()).parse::<u64>() {
            Ok(id) => id,
            Err(e) => {
                println!("Could not parse channel id {}", e);
                return;
            }
        };
        let channel = ChannelId(status_channel_id);
        tokio::spawn(async move {
            let old_msgs = channel.messages(&ctx, |b| b)
                .await.unwrap();
            channel.delete_messages(&ctx, old_msgs).await;
            let mut status = get_status_string().await.unwrap_or("Unknown".to_string());
            let msg_id = channel.send_message(&ctx.http, |m| {
                m.embed(|e| {
                        e.title("Server Status")
                            .description(status)
                    })
            }).await.unwrap().id;
            loop {
                tokio::time::sleep(Duration::from_secs(60)).await;
                status = get_status_string().await.unwrap_or("Unknown".to_string());
                channel.edit_message(&ctx.http, msg_id, |m| {
                    m.embed(|e| {
                            e.title("Server Status")
                                .description(status)
                        })
                }).await;
            }
        });
    }
}

#[group]
#[commands(status, my_id)]
struct General;

#[group]
#[owners_only]
#[summary = "Commands for server owners"]
#[commands(commands, latency, startup, shutdown)]
struct Owner;

#[help]
#[individual_command_tip = "Hello! こんにちは！Hola! Bonjour! 您好! 안녕하세요~\n\n\
If you want more information about a specific command, just pass the command as argument."]
#[command_not_found_text = "Could not find: `{}`."]
#[max_levenshtein_distance(3)]
#[indention_prefix = "+"]
#[lacking_permissions = "Hide"]
#[lacking_role = "Nothing"]
#[wrong_channel = "Strike"]
async fn my_help(
    context: &Context,
    msg: &Message,
    args: Args,
    help_options: &'static HelpOptions,
    groups: &[&'static CommandGroup],
    owners: HashSet<UserId>,
) -> CommandResult {
    let _ = help_commands::with_embeds(context, msg, args, help_options, groups, owners).await;
    Ok(())
}

#[hook]
async fn before(ctx: &Context, msg: &Message, command_name: &str) -> bool {
    println!("Got command '{}' by user '{}'", command_name, msg.author.name);

    let mut data = ctx.data.write().await;
    let counter = data.get_mut::<CommandCounter>().expect("Expected CommandCounter in TypeMap.");
    let entry = counter.entry(command_name.to_string()).or_insert(0);
    *entry += 1;

    true
}

#[hook]
async fn after(_ctx: &Context, _msg: &Message, command_name: &str, command_result: CommandResult) {
    match command_result {
        Ok(()) => println!("Processed command '{}'", command_name),
        Err(why) => println!("Command '{}' returned error {:?}", command_name, why),
    }
}

#[hook]
async fn unknown_command(_ctx: &Context, _msg: &Message, unknown_command_name: &str) {
    println!("Could not find command named '{}'", unknown_command_name);
}

#[hook]
async fn delay_action(ctx: &Context, msg: &Message) {
    let _ = msg.react(ctx, '⏱').await;
}

#[hook]
async fn dispatch_error(ctx: &Context, msg: &Message, error: DispatchError) {
    if let DispatchError::Ratelimited(info) = error {
        if info.is_first_try {
            let _ = msg
                .channel_id
                .say(&ctx.http, &format!("Try this again in {} seconds.", info.as_secs()))
                .await;
        }
    }
}

#[tokio::main]
async fn main() {
    let token = env::var("DISCORD_TOKEN").expect("Expected a token in the environment");
    let http = Http::new_with_token(&token);
    let (owners, bot_id) = match http.get_current_application_info().await {
        Ok(info) => {
            let mut owners = HashSet::new();
            if let Some(team) = info.team {
                owners.insert(team.owner_user_id);
            } else {
                owners.insert(info.owner.id);
            }
            match env::var("OWNER_IDS") {
                Ok(owner_ids) => {
                    for id in owner_ids.split(",") {
                        owners.insert(UserId::from(id.parse::<u64>().unwrap()));
                    }
                }
                Err(_) => {}
            }
            match http.get_current_user().await {
                Ok(bot_id) => (owners, bot_id.id),
                Err(why) => panic!("Could not access the bot id: {:?}", why),
            }
        },
        Err(why) => panic!("Could not access application info: {:?}", why),
    };

    let framework = StandardFramework::new()
        .configure(|c| c
            .with_whitespace(true)
            .on_mention(Some(bot_id))
            .prefix("~")
            .delimiters(vec![", ", ","])
            .owners(owners))
        .before(before)
        .after(after)
        .unrecognised_command(unknown_command)
        .on_dispatch_error(dispatch_error)
        .help(&MY_HELP)
        .group(&GENERAL_GROUP)
        .group(&OWNER_GROUP);

    let mut client = Client::builder(&token)
        .event_handler(Handler)
        .framework(framework)
        .intents(GatewayIntents::all())
        .type_map_insert::<CommandCounter>(HashMap::default())
        .await
        .expect("Err creating client");

    {
        let mut data = client.data.write().await;
        data.insert::<ShardManagerContainer>(Arc::clone(&client.shard_manager));
    }

    if let Err(why) = client.start().await {
        println!("Client error: {:?}", why);
    }
}

#[command]
async fn status(ctx: &Context, msg: &Message) -> CommandResult {
    msg.channel_id.say(&ctx.http, get_status_string().await?).await?;
    Ok(())
}

async fn get_status_string() -> Result<String, CommandError> {
    let is_server_up = match mc_metrics::is_server_up().await {
        Ok(is_server_up) => is_server_up,
        Err(e) => {
            println!("Failed to capture server liveness {:?}", e);
            false
        }
    };
    let server_name = env::var("SERVER_HOSTNAME")
        .unwrap_or("The server".to_string());
    let server_liveness_msg = match is_server_up {
        true => server_name + " is UP :green_circle:",
        false => server_name + " is DOWN :red_circle:",
    };
    if !is_server_up {
        return Ok(server_liveness_msg.to_string());
    }
    let player_count = match mc_metrics::get_player_count().await {
        Ok(player_count) => player_count,
        Err(e) => {
            println!("Failed to capture player count {:?}", e);
            0
        }
    };
    let players_online_msg = format!("Players online: {}", player_count);
    let avg_tps = match mc_metrics::get_5m_tps().await {
        Ok(avg_tps) => avg_tps,
        Err(e) => {
            println!("Failed to capture average tps {:?}", e);
            0.0
        }
    };
    let avg_tps_msg = format!("Average Ticks per Second: {}, \
    Target Ticks per Second: 20", avg_tps);

    let endpoint = env::var("SHUTDOWN_TIME_ENDPOINT")?;
    let shutdown_msg = match ReqClient::new().get(endpoint).send().await {
        Ok(resp) => {
            let body = resp.text().await
                .map_err(|e| CommandError::from(e))?.trim_matches('"').to_string();
            format!("{} until shutdown",
                    fmt_duration_until_shutdown(body)?)
        },
        Err(e) => {
            println!("Could not query server shutdown time {}", e);
            "Unknown time until shutdown".to_string()
        }
    };

    Ok(format!("\n{}\n{}\n{}\n{}", server_liveness_msg, players_online_msg, avg_tps_msg, shutdown_msg))
}

#[command]
async fn my_id(ctx: &Context, msg: &Message) -> CommandResult {
    let account_id = msg.author.id.0;
    msg.channel_id.say(&ctx.http, format!("Your id is {}", account_id)).await?;

    Ok(())
}

#[command]
async fn latency(ctx: &Context, msg: &Message) -> CommandResult {
    let data = ctx.data.read().await;

    let shard_manager = match data.get::<ShardManagerContainer>() {
        Some(v) => v,
        None => {
            msg.reply(ctx, "There was a problem getting the shard manager").await?;

            return Ok(());
        },
    };

    let manager = shard_manager.lock().await;
    let runners = manager.runners.lock().await;

    let runner = match runners.get(&ShardId(ctx.shard_id)) {
        Some(runner) => runner,
        None => {
            msg.reply(ctx, "No shard found").await?;

            return Ok(());
        },
    };

    msg.reply(ctx, &format!("The shard latency is {:?}", runner.latency)).await?;

    Ok(())
}

#[command]
async fn commands(ctx: &Context, msg: &Message) -> CommandResult {
    let mut contents = "Commands used:\n".to_string();

    let data = ctx.data.read().await;
    let counter = data.get::<CommandCounter>().expect("Expected CommandCounter in TypeMap.");

    for (k, v) in counter {
        writeln!(contents, "- {name}: {amount}", name = k, amount = v)?;
    }

    msg.channel_id.say(&ctx.http, &contents).await?;

    Ok(())
}

use reqwest::Client as ReqClient;
use serenity::model::id::ChannelId;
use tokio::time::Duration;

#[command]
#[aliases("start")]
async fn startup(ctx: &Context, msg: &Message) -> CommandResult {
    let endpoint = env::var("START_ENDPOINT")?;
    match ReqClient::new().get(endpoint).send().await {
        Ok(resp) => {
            let body = resp.text().await
                .map_err(|e| CommandError::from(e))?.trim_matches('"').to_string();
            let resp = format!("The server is starting and is scheduled to shut down in {}",
                               fmt_duration_until_shutdown(body)?);
            msg.channel_id.say(&ctx.http, resp).await?;
            Ok(())
        },
        Err(e) => {
            msg.channel_id.say(&ctx.http, "Startup has failed").await?;
            Err(CommandError::from(e))
        }
    }
}

fn fmt_duration_until_shutdown(shutdown_time_token: String) -> Result<String, CommandError> {
    let shutdown_time = DateTime::parse_from_rfc3339(shutdown_time_token.as_str())
        .map_err(|e| CommandError::from(e))?
        .duration_round(chrono::Duration::minutes(1))
        .map_err(|e| CommandError::from(e))?;
    let now = Utc::now().duration_round(chrono::Duration::minutes(1))
        .map_err(|e| CommandError::from(e))?;
    let duration_until_shutdown = shutdown_time.signed_duration_since(now);
    Ok(humantime::format_duration(duration_until_shutdown.to_std()
        .map_err(|e| CommandError::from(e))?).to_string())
}

#[command]
#[aliases("stop")]
async fn shutdown(ctx: &Context, msg: &Message) -> CommandResult {
    let endpoint = env::var("STOP_ENDPOINT")?;
    match ReqClient::new().get(endpoint).send().await {
        Ok(_) => {
            msg.channel_id.say(&ctx.http, "Shutdown has begun").await?;
            Ok(())
        },
        Err(e) => {
            msg.channel_id.say(&ctx.http, "Shutdown has failed").await?;
            Err(CommandError::from(e))
        }
    }
}
