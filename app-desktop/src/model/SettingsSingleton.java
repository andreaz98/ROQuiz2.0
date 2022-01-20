package model;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonIOException;
import com.google.gson.JsonSyntaxException;
import com.google.gson.stream.JsonReader;

public class SettingsSingleton {
	public final static double VERSION_NUMBER = 1.3;
	public final static int DEFAULT_QUESTION_NUMBER = 16;
	public final static int DEFAULT_ANSWER_NUMBER = 5;
	public final static int DEFAULT_TIMER = 18;
	public final static boolean DEFAULT_CHECK_QUESTIONS_UPDATE = true;
	public final static boolean DEFAULT_DARK_MODE = false;
	
	private static SettingsSingleton instance = null;
	
	private static boolean justLaunched;
	
	private Settings settings;
	
	private SettingsSingleton()
	{
		justLaunched = true;
		
		settings = new Settings(DEFAULT_QUESTION_NUMBER, DEFAULT_TIMER, DEFAULT_CHECK_QUESTIONS_UPDATE, DEFAULT_DARK_MODE);
		
		settings = this.loadSettings(".settings.json");
	}

	public static synchronized SettingsSingleton getInstance()
	{
		if(instance == null)
			instance = new SettingsSingleton();
		return instance;
	}

	public boolean isJustLaunched() {return justLaunched;}
	public void setJustLaunched(boolean justLaunched) {SettingsSingleton.justLaunched = justLaunched;}
	
	public int getQuestionNumber() {return this.settings.getQuestionNumber();}
	public void setQuestionNumber(int qNum) {this.settings.setQuestionNumber(qNum);}
	public int getTimer() {return this.settings.getTimer();}
	public void setTimer(int sTime) {this.settings.setTimer(sTime);}
	public boolean isCheckQuestionsUpdate() {return this.settings.isCheckQuestionsUpdate();}
	public void setCheckQuestionsUpdate(boolean qUpdate) {this.settings.setCheckQuestionsUpdate(qUpdate);}
	public boolean isDarkMode() {return this.settings.isDarkMode();}
	public void setDarkMode(boolean dMode) {this.settings.setDarkMode(dMode);}

	public Settings loadSettings(String filename) {
		try (JsonReader reader = new JsonReader(new FileReader(filename))) {
			Gson gson = new GsonBuilder().excludeFieldsWithModifiers(java.lang.reflect.Modifier.TRANSIENT).create(); // need this since we use a static class
			
			this.settings = new Settings();
			this.settings = gson.fromJson(reader, Settings.class);
			
			/*System.out.println("Impostazioni caricate\nNumero domande per quiz: " + this.settings.getQuestionNumber() + 
					"\nTimer per quiz (Minuti): " + this.settings.getTimer() + "\nControllo domande aggiornate: " + this.settings.isCheckQuestionsUpdate() +
					"\nTema scuro: " + this.settings.isDarkMode());*/
			
			return this.settings;
		} catch (NullPointerException | IOException | JsonIOException | JsonSyntaxException e) {
			System.out.println("File delle impostazioni corrotto o assente, verr� ricreato con le impostazioni predefinite.");
			this.resetSettings(filename);
			return this.settings;
		}
	}
	
	public void saveSettings(Settings s, String filename) {
		try(FileWriter writer = new FileWriter(filename)) {
			Gson gson = new GsonBuilder().excludeFieldsWithModifiers(java.lang.reflect.Modifier.TRANSIENT).setPrettyPrinting().create();
			gson.toJson(s, writer);
	        
	        /*System.out.println("Impostazioni salvate\nNumero domande per quiz: " + settings.getQuestionNumber() + 
					"\nTimer per quiz (Minuti): " + settings.getTimer() + "\nControllo domande aggiornate: " + settings.isCheckQuestionsUpdate() +
					"\nTema scuro: " + settings.isDarkMode());*/
		} catch (JsonIOException | IOException e) {
			System.out.println("Errore nel salvataggio del file delle impostazioni. Verr� ripristinato.");
			this.resetSettings(filename);
		}
	}
	public void saveSettings(String filename) {
		this.saveSettings(this.settings, filename);
	}
	
	public void resetSettings(String filename) {
		
		try(FileWriter writer = new FileWriter(filename)) {
			Settings s = new Settings(DEFAULT_QUESTION_NUMBER, DEFAULT_TIMER, DEFAULT_CHECK_QUESTIONS_UPDATE, DEFAULT_DARK_MODE);
			
			Gson gson = new GsonBuilder().excludeFieldsWithModifiers(java.lang.reflect.Modifier.TRANSIENT).setPrettyPrinting().create();
			gson.toJson(s, writer);
			
			/*System.out.println("Impostazioni predefinite ripristinate\nNumero domande per quiz: " + DEFAULT_QUESTION_NUMBER + 
					"\nTimer per quiz (Minuti): " + DEFAULT_TIMER + "\nControllo domande aggiornate: " + DEFAULT_CHECK_QUESTIONS_UPDATE +
					"\nTema scuro: " + DEFAULT_DARK_MODE);*/
		} catch (JsonIOException | IOException e) {
			System.out.println("Errore durante il ripristino del file delle impostazioni.");
			System.exit(1);
		}
	}
}