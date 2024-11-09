    interface Medication {
        name: string;
        dose: string;
        route: string;
        freq: string;
        dur: string;
        class: string;
    }
    
    interface Test {
        name: string;
        instruction: string;
        date: string;
    }
    
    interface Followup {
        date: string;
        reason: string;
    }
    
    interface Vitals {
        BP: string;
        Heartrate: string;
        "Respiratory rate": string;
        temp: string;
        spO2: string;
    }
    
    interface NursingInstruction {
        instruction: string;
        priority: string;
    }
    
    interface Discharge {
        planned_date: string;
        instruction: string;
        Home_Care: string;
        Recommendations: string;
    }
    
    interface Prescription {
        medication: Medication[];
        test: Test[];
        followup: Followup;
        vitals: Vitals;
        nursing: NursingInstruction[];
        discharge: Discharge;
        notes: string[];
    }