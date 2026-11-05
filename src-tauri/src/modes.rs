//! Modos por app: la misma frase se escribe distinto en un correo, en un chat
//! o en un editor de código. Cada modo lista las apps donde aplica y unos
//! retoques gratis (sin IA) que se hacen justo antes de pegar.
//!
//! Una app se nombra con su identificador de macOS (`com.apple.mail`), con el
//! nombre del programa en Windows (`outlook.exe`) o con su nombre visible
//! («Mail»). Así una misma lista sirve en los dos sistemas.

use log::{debug, warn};
use serde::{Deserialize, Serialize};
use specta::Type;
use std::time::{Duration, Instant};
use tauri::AppHandle;

use crate::settings::{get_settings, write_settings};

/// La primera letra del texto pegado.
#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq, Eq, Type, Default)]
#[serde(rename_all = "snake_case")]
pub enum FirstLetter {
    /// Como salió de la transcripción.
    #[default]
    AsIs,
    Upper,
    Lower,
}

/// El punto final del texto pegado.
#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq, Eq, Type, Default)]
#[serde(rename_all = "snake_case")]
pub enum EndMark {
    #[default]
    AsIs,
    /// Quita el punto final, como se escribe en un chat.
    Remove,
    /// Cierra con punto si la frase no termina en una marca.
    Add,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Type)]
pub struct Mode {
    pub id: String,
    pub name: String,
    /// Identificadores, nombres de programa o nombres visibles de las apps.
    #[serde(default)]
    pub apps: Vec<String>,
    #[serde(default)]
    pub first_letter: FirstLetter,
    #[serde(default)]
    pub end_mark: EndMark,
    /// Junta todo en una línea (sin saltos), como en una caja de búsqueda.
    #[serde(default)]
    pub single_line: bool,
}

/// La app que tiene el foco.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Type)]
pub struct ActiveApp {
    /// Bundle id en macOS, nombre del programa en Windows.
    pub id: String,
    pub name: String,
    #[serde(skip)]
    #[specta(skip)]
    pub pid: u32,
}

pub fn default_modes() -> Vec<Mode> {
    let apps = |list: &[&str]| list.iter().map(|s| s.to_string()).collect::<Vec<_>>();
    vec![
        Mode {
            id: "correo".into(),
            name: "Correo".into(),
            apps: apps(&[
                "com.apple.mail",
                "com.microsoft.Outlook",
                "outlook.exe",
                "olk.exe",
                "com.readdle.smartemail-Mac",
            ]),
            first_letter: FirstLetter::Upper,
            end_mark: EndMark::Add,
            single_line: false,
        },
        Mode {
            id: "mensajes".into(),
            name: "Mensajes".into(),
            apps: apps(&[
                "net.whatsapp.WhatsApp",
                "whatsapp.exe",
                "com.tinyspeck.slackmacgap",
                "slack.exe",
                "com.apple.MobileSMS",
                "ru.keepcoder.Telegram",
                "telegram.exe",
                "com.hnc.Discord",
                "discord.exe",
            ]),
            first_letter: FirstLetter::AsIs,
            end_mark: EndMark::Remove,
            single_line: true,
        },
        Mode {
            id: "codigo".into(),
            name: "Código".into(),
            apps: apps(&[
                "com.apple.Terminal",
                "com.googlecode.iterm2",
                "com.microsoft.VSCode",
                "code.exe",
                "com.todesktop.230313mzl4w4u92",
                "cursor.exe",
                "windowsterminal.exe",
                "powershell.exe",
            ]),
            first_letter: FirstLetter::Lower,
            end_mark: EndMark::Remove,
            single_line: true,
        },
        Mode {
            id: "notas".into(),
            name: "Notas".into(),
            apps: apps(&[
                "com.apple.Notes",
                "md.obsidian",
                "obsidian.exe",
                "notion.id",
                "notion.exe",
            ]),
            first_letter: FirstLetter::Upper,
            end_mark: EndMark::AsIs,
            single_line: false,
        },
    ]
}

/// Minúsculas y sin «.exe», para comparar `Outlook.EXE` con `outlook.exe`.
fn norm(s: &str) -> String {
    let s = s.trim().to_lowercase();
    s.strip_suffix(".exe").map(str::to_string).unwrap_or(s)
}

pub fn find_mode<'a>(modes: &'a [Mode], app: &ActiveApp) -> Option<&'a Mode> {
    let id = norm(&app.id);
    let name = norm(&app.name);
    modes.iter().find(|m| {
        m.apps.iter().any(|a| {
            let a = norm(a);
            !a.is_empty() && (a == id || a == name)
        })
    })
}

const END_MARKS: &[char] = &['.', '?', '!', '…', ':', ';', ',', ')', '"', '»', '”'];

/// Un nombre en mayúsculas («API», «SQL») no se baja a minúscula.
fn looks_like_acronym(text: &str) -> bool {
    let first_word: String = text.chars().take_while(|c| !c.is_whitespace()).collect();
    first_word.chars().filter(|c| c.is_uppercase()).count() >= 2
}

pub fn apply(mode: &Mode, text: &str) -> String {
    let trailing: String = text
        .chars()
        .rev()
        .take_while(|c| c.is_whitespace())
        .collect::<Vec<_>>()
        .into_iter()
        .rev()
        .collect();
    let mut out = text.trim().to_string();
    if out.is_empty() {
        return text.to_string();
    }

    if mode.single_line {
        out = out.split_whitespace().collect::<Vec<_>>().join(" ");
    }

    match mode.first_letter {
        FirstLetter::AsIs => {}
        FirstLetter::Upper => {
            let mut chars = out.chars();
            if let Some(first) = chars.next() {
                out = first.to_uppercase().chain(chars).collect();
            }
        }
        FirstLetter::Lower => {
            if !looks_like_acronym(&out) {
                let mut chars = out.chars();
                if let Some(first) = chars.next() {
                    out = first.to_lowercase().chain(chars).collect();
                }
            }
        }
    }

    match mode.end_mark {
        EndMark::AsIs => {}
        EndMark::Remove => {
            // Un solo punto final; «...» y «?» se respetan.
            if out.ends_with('.') && !out.ends_with("..") {
                out.pop();
            }
        }
        EndMark::Add => {
            if let Some(last) = out.chars().last() {
                if !END_MARKS.contains(&last) {
                    out.push('.');
                }
            }
        }
    }

    out + &trailing
}

/// Aplica el modo de la app que tiene el foco, si hay uno. Es lo último que
/// se le hace al texto antes de pegarlo.
pub fn apply_for_active_app(app: &AppHandle, text: String) -> String {
    let settings = get_settings(app);
    if !settings.modes_enabled || settings.modes.is_empty() {
        return text;
    }
    let Some(active) = active_app() else {
        return text;
    };
    match find_mode(&settings.modes, &active) {
        Some(mode) => {
            debug!("Mode '{}' applies for app '{}'", mode.name, active.id);
            apply(mode, &text)
        }
        None => text,
    }
}

#[cfg(target_os = "macos")]
pub fn active_app() -> Option<ActiveApp> {
    use objc2_app_kit::NSWorkspace;
    let app = NSWorkspace::sharedWorkspace().frontmostApplication()?;
    let id = app.bundleIdentifier().map(|s| s.to_string())?;
    let name = app
        .localizedName()
        .map(|s| s.to_string())
        .unwrap_or_else(|| id.clone());
    Some(ActiveApp {
        id,
        name,
        pid: app.processIdentifier() as u32,
    })
}

#[cfg(target_os = "windows")]
pub fn active_app() -> Option<ActiveApp> {
    use windows::core::PWSTR;
    use windows::Win32::Foundation::CloseHandle;
    use windows::Win32::System::Threading::{
        OpenProcess, QueryFullProcessImageNameW, PROCESS_NAME_WIN32,
        PROCESS_QUERY_LIMITED_INFORMATION,
    };
    use windows::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowThreadProcessId};

    // SAFETY: llamadas de solo lectura a la API de Windows; el buffer vive
    // durante la llamada y el handle se cierra antes de salir.
    unsafe {
        let hwnd = GetForegroundWindow();
        if hwnd.0.is_null() {
            return None;
        }
        let mut pid = 0u32;
        GetWindowThreadProcessId(hwnd, Some(&mut pid));
        if pid == 0 {
            return None;
        }
        let handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid).ok()?;
        let mut buf = [0u16; 1024];
        let mut len = buf.len() as u32;
        let result = QueryFullProcessImageNameW(
            handle,
            PROCESS_NAME_WIN32,
            PWSTR(buf.as_mut_ptr()),
            &mut len,
        );
        let _ = CloseHandle(handle);
        result.ok()?;
        let path = String::from_utf16_lossy(&buf[..len as usize]);
        let file = path.rsplit(['\\', '/']).next().unwrap_or(&path).to_string();
        let name = file.strip_suffix(".exe").unwrap_or(&file).to_string();
        Some(ActiveApp {
            id: file,
            name,
            pid,
        })
    }
}

#[cfg(not(any(target_os = "macos", target_os = "windows")))]
pub fn active_app() -> Option<ActiveApp> {
    None
}

fn clean_modes(modes: Vec<Mode>) -> Vec<Mode> {
    let mut seen = std::collections::HashSet::new();
    modes
        .into_iter()
        .filter_map(|mut m| {
            m.name = m.name.trim().to_string();
            if m.name.is_empty() || m.id.trim().is_empty() || !seen.insert(m.id.clone()) {
                return None;
            }
            let mut apps_seen = std::collections::HashSet::new();
            m.apps = m
                .apps
                .into_iter()
                .map(|a| a.trim().to_string())
                .filter(|a| !a.is_empty() && apps_seen.insert(norm(a)))
                .collect();
            Some(m)
        })
        .collect()
}

#[tauri::command]
#[specta::specta]
pub fn set_modes(app: AppHandle, modes: Vec<Mode>) -> Result<(), String> {
    let mut settings = get_settings(&app);
    settings.modes = clean_modes(modes);
    write_settings(&app, settings);
    Ok(())
}

#[tauri::command]
#[specta::specta]
pub fn change_modes_enabled_setting(app: AppHandle, enabled: bool) -> Result<(), String> {
    let mut settings = get_settings(&app);
    settings.modes_enabled = enabled;
    write_settings(&app, settings);
    Ok(())
}

/// Espera a que la persona cambie a otra app y devuelve cuál es. Sirve para
/// «agregar la app» sin que tenga que saber su identificador.
#[tauri::command]
#[specta::specta]
pub async fn detect_app(seconds: u32) -> Result<Option<ActiveApp>, String> {
    let own = std::process::id();
    let deadline = Instant::now() + Duration::from_secs(u64::from(seconds.clamp(1, 20)));
    tauri::async_runtime::spawn_blocking(move || {
        while Instant::now() < deadline {
            if let Some(found) = active_app() {
                if found.pid != own {
                    return Some(found);
                }
            }
            std::thread::sleep(Duration::from_millis(250));
        }
        warn!("detect_app: no other app took focus in time");
        None
    })
    .await
    .map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mode(first: FirstLetter, end: EndMark, single: bool) -> Mode {
        Mode {
            id: "t".into(),
            name: "T".into(),
            apps: vec![],
            first_letter: first,
            end_mark: end,
            single_line: single,
        }
    }

    #[test]
    fn email_gets_capital_and_period() {
        let m = mode(FirstLetter::Upper, EndMark::Add, false);
        assert_eq!(
            apply(&m, "hola rosario, te escribo por la sesión"),
            "Hola rosario, te escribo por la sesión."
        );
        assert_eq!(apply(&m, "¿vienes mañana?"), "¿vienes mañana?");
        assert_eq!(apply(&m, "listo."), "Listo.");
    }

    #[test]
    fn chat_drops_the_final_period_but_keeps_ellipsis_and_questions() {
        let m = mode(FirstLetter::AsIs, EndMark::Remove, true);
        assert_eq!(apply(&m, "Te confirmo mañana."), "Te confirmo mañana");
        assert_eq!(apply(&m, "No sé..."), "No sé...");
        assert_eq!(apply(&m, "¿Vienes?"), "¿Vienes?");
        assert_eq!(apply(&m, "Uno.\nDos."), "Uno. Dos");
    }

    #[test]
    fn code_lowercases_unless_it_is_an_acronym() {
        let m = mode(FirstLetter::Lower, EndMark::Remove, true);
        assert_eq!(apply(&m, "Git commit menos m."), "git commit menos m");
        assert_eq!(apply(&m, "API de pagos."), "API de pagos");
    }

    #[test]
    fn trailing_space_survives_and_empty_text_is_untouched() {
        let m = mode(FirstLetter::Upper, EndMark::Add, false);
        assert_eq!(apply(&m, "hola "), "Hola. ");
        assert_eq!(apply(&m, "   "), "   ");
    }

    #[test]
    fn modes_match_by_bundle_id_exe_or_name_ignoring_case() {
        let modes = default_modes();
        let mac = ActiveApp {
            id: "com.apple.mail".into(),
            name: "Mail".into(),
            pid: 1,
        };
        let win = ActiveApp {
            id: "OUTLOOK.EXE".into(),
            name: "OUTLOOK".into(),
            pid: 1,
        };
        let other = ActiveApp {
            id: "com.apple.Safari".into(),
            name: "Safari".into(),
            pid: 1,
        };
        assert_eq!(find_mode(&modes, &mac).unwrap().id, "correo");
        assert_eq!(find_mode(&modes, &win).unwrap().id, "correo");
        assert!(find_mode(&modes, &other).is_none());
    }

    #[test]
    fn clean_modes_drops_blank_and_duplicate_entries() {
        let cleaned = clean_modes(vec![
            Mode {
                id: "a".into(),
                name: " A ".into(),
                apps: vec!["Slack".into(), "slack.exe".into(), " ".into()],
                first_letter: FirstLetter::AsIs,
                end_mark: EndMark::AsIs,
                single_line: false,
            },
            Mode {
                id: "a".into(),
                name: "B".into(),
                apps: vec![],
                first_letter: FirstLetter::AsIs,
                end_mark: EndMark::AsIs,
                single_line: false,
            },
            Mode {
                id: "c".into(),
                name: " ".into(),
                apps: vec![],
                first_letter: FirstLetter::AsIs,
                end_mark: EndMark::AsIs,
                single_line: false,
            },
        ]);
        assert_eq!(cleaned.len(), 1);
        assert_eq!(cleaned[0].name, "A");
        assert_eq!(cleaned[0].apps, vec!["Slack".to_string()]);
    }
}
