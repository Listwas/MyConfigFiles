using System.Collections;
using UnityEngine;

public class CombatScript : MonoBehaviour
{
    [Header("References")]
    public ComboSystem comboSystem;
    public Animator animator;
    private FloatingHealthBar healthBar;
    private bloodCount blood;
    
    [Header("Combat Settings")]
    public LayerMask enemy_layers;

    [Header("Light Attack")]
    public int lightAttackDamage = 5;
    public float lightAttackRange = 2f;
    public float lightAttackCooldown = 0.5f;
    
    [Header("Heavy Attack")]
    public int heavyAttackDamage = 10;
    public float heavyAttackRange = 3f;
    public float heavyAttackCooldown = 1.0f;

    [Header("Player Stats")]
    public int currentHealth = 100;
    public int maxHealth = 100;
    private bool hasDied = false;
    
    [Header("Parry Settings")]
    public bool isParrying = false;
    public float parryDuration = 0.5f;
    public float parryRange = 1.5f;
    private float parryEndTime;

    [Header("Debug Options")]
    public bool lightAttackDebug;
    public bool heavyAttackDebug;
    public bool comboExecutedDebug;
    public bool showAttackRange;
    public bool showParryRange;
    public bool takenDamageDebug;

    private float lastLightAttackTime;
    private float lastHeavyAttackTime;

    private void Start()
    {
        comboSystem = GetComponent<ComboSystem>();
        comboSystem.OnComboExecuted += ExecuteComboEffect;
        healthBar = GetComponentInChildren<FloatingHealthBar>();
        blood = FindObjectOfType<bloodCount>();
        healthBar.DoHealthBar(currentHealth, maxHealth);
    }

    private void Update()
    {
        healthBar.DoHealthBar(currentHealth, maxHealth);
    }

    public void ProcessPlayerInput()
    {
        if (CanAttack("LightAttack", KeyCode.Q, lastLightAttackTime, lightAttackCooldown))
        {
            ExecuteLightAttack();
            lastLightAttackTime = Time.time;
        }
        else if (CanAttack("HeavyAttack", KeyCode.E, lastHeavyAttackTime, heavyAttackCooldown))
        {
            ExecuteHeavyAttack();
            lastHeavyAttackTime = Time.time;
        }
        
        if (Input.GetButtonDown("Parry") || Input.GetKeyDown(KeyCode.F))
        {
            StartParry();
        }
    }

    private bool CanAttack(string button, KeyCode key, float lastAttackTime, float cooldown)
    {
        return (Input.GetButtonDown(button) || Input.GetKeyDown(key)) && Time.time >= lastAttackTime + cooldown;
    }

    public bool IsParrying()
    {
        return is_parrying;
    }

    private void StartParry()
    {
        isParrying = true;
        parryEndTime = Time.time + parryDuration;
        animator.SetTrigger("parry");
        Debug.Log("Player started parrying!");
    }

    private void ExecuteComboEffect(ComboSystem.DamageType damageType, int totalDamage)
    {
        if (comboExecutedDebug)
            Debug.Log($"Combo executed: {damageType}, total damage: {totalDamage}");
        
        float attackRange = damageType == ComboSystem.DamageType.Slash ? lightAttackRange : heavyAttackRange;
        ApplyAttackDamage(totalDamage, attackRange);
    }

    private void ExecuteLightAttack()
    {
        ExecuteAttack(ComboSystem.AttackType.Light, lightAttackDamage, lightAttackRange, "fast attack", lightAttackDebug);
    }

    private void ExecuteHeavyAttack()
    {
        ExecuteAttack(ComboSystem.AttackType.Heavy, heavyAttackDamage, heavyAttackRange, "heavy attack", heavyAttackDebug);
    }

    private void ExecuteAttack(ComboSystem.AttackType type, int baseDamage, float range, string animationTrigger, bool debug)
    {
        comboSystem.RegisterAttack(type);
        int actualDamage = (int)(baseDamage * blood.DMGMulti);
        bool hitEnemy = ApplyAttackDamage(actualDamage, range);
        animator.SetTrigger(animationTrigger);

        if (debug)
            Debug.Log($"{type} Attack: Damage={actualDamage}, Cooldown={lightAttackCooldown}s, Hit={(hitEnemy ? "enemy" : "nothing")}");
    }

    private bool ApplyAttackDamage(int damage, float range)
    {
        Collider[] hitEnemies = Physics.OverlapSphere(transform.position + transform.forward, range, enemy_layers);
        
        if (hitEnemies.Length > 0)
        {
            foreach (Collider enemy in hitEnemies)
            {
                enemy.GetComponent<EnemyScript>()?.TakeDamage(damage);
            }
            return true;
        }
        return false;
    }

    public void TakeDamage(int damageAmount)
    {
        if (isParrying)
        {
            Debug.Log("Parry successful! No damage taken.");
            return;
        }
        
        currentHealth -= damageAmount;
        if (currentHealth > 0)
        {
            if (takenDamageDebug)
                Debug.Log($"Player took {damageAmount} damage. Current health: {currentHealth}");
        }
        else if (!hasDied)
        {
            hasDied = true;
            Debug.Log("Player died!");
        }
    }

    public void Heal(int healAmount)
    {
        currentHealth = Mathf.Min(currentHealth + healAmount, maxHealth);
    }

    public IEnumerator TimedHealing(int healAmount)
    {
        for (int i = 0; i < 5; i++)
        {
            Heal(healAmount);
            yield return new WaitForSeconds(3);
        }
    }
public IEnumerator HealOverTime(int healAmount, int times, float interval)
{
    for (int i = 0; i < times; i++)
    {
        current_health += healAmount;
        if (current_health > max_health)
        {
            current_health = max_health;
        }
        yield return new WaitForSeconds(interval);
    }
}

    

    private void OnDrawGizmos()
    {
        if (showAttackRange)
        {
            DrawGizmoSphere(Color.green, lightAttackRange);
            DrawGizmoSphere(Color.red, heavyAttackRange);
        }
        
        if (showParryRange)
        {
            DrawGizmoSphere(Color.blue, parryRange);
        }
    }

    private void DrawGizmoSphere(Color color, float range)
    {
        Gizmos.color = color;
        Gizmos.DrawWireSphere(transform.position + transform.forward, range);
    }
}
