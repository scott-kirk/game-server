use std::env;
use std::env::VarError;
use std::num::{ParseFloatError, ParseIntError};
use std::str::ParseBoolError;
use reqwest::Client;
use serde_json::Value;

#[derive(Debug)]
pub enum MetricsError {
    Env(VarError),
    Http(reqwest::Error),
    ParseFloatError(ParseFloatError),
}

#[derive(Debug)]
struct ParseError {
    details: String
}

pub async fn get_player_count() -> Result<u32, MetricsError> {
    let player_count: f32 = get_metric("sum(mc_players_online_total)").await?
        .parse().map_err(|e| MetricsError::ParseFloatError(e))?;
    Ok(player_count.round() as u32)
}

pub async fn is_server_up() -> Result<bool, MetricsError> {
    let server_liveness: f32 = get_metric("up").await?.parse()
        .map_err(|e| MetricsError::ParseFloatError(e))?;
    match server_liveness.round() as u32 {
        1 => Ok(true),
        _ => Ok(false),
    }
}

pub async fn get_5m_tps() -> Result<f32, MetricsError> {
    get_metric("avg_over_time(mc_tps[5m])").await?.parse()
        .map_err(|e| MetricsError::ParseFloatError(e))
}

pub async fn get_metric(query: &str) -> Result<String, MetricsError> {
    let host = env::var("PROMETHEUS_URL")
        .map_err(|e| MetricsError::Env(e))?;
    let endpoint = host + "api/v1/query?query=" + query;
    let text = Client::new().get(endpoint)
        .send().await.map_err(|e| MetricsError::Http(e))?
        .text().await.map_err(|e| MetricsError::Http(e))?;
    let metric_payload: Value = serde_json::from_str(text.as_ref()).unwrap();
    Ok(metric_payload["data"]["result"][0]["value"][1].to_string()
        .trim_matches('"').to_string())
}
